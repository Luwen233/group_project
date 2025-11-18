const express = require('express');
const app = express();
const bcrypt = require('bcrypt');
const con = require('./db'); // Database connection
const jwt = require('jsonwebtoken');
const cookieParser = require('cookie-parser');
const multer = require('multer');
const path = require('path');
const cors = require('cors');

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cookieParser());

const JWT_KEY = 'm0bile2Simple';

// ================= Middleware ================
function verifyAccess(allowedRoles) {
  return (req, res, next) => {
    let token = req.headers['authorization'] || req.headers['x-access-token'];
    if (token == undefined || token == null) {
      return res.status(400).send('No token');
    }

    if (req.headers.authorization) {
      const tokenString = token.split(' ');
      if (tokenString[0] == 'Bearer') {
        token = tokenString[1];
      }
    }

    jwt.verify(token, JWT_KEY, (err, decoded) => {
      if (err) {
        return res.status(401).send('Incorrect token');
      }

      if (!decoded || !decoded.role) {
        return res.status(403).json({ message: 'Forbidden: No role found in token' });
      }

      const userRole = decoded.role.toLowerCase();

      const isAllowed = allowedRoles
        .map(role => role.toLowerCase())
        .includes(userRole);

      if (!isAllowed) {
        return res.status(403).json({ message: 'Forbidden: Insufficient permissions' });
      }
      req.decoded = decoded;
      next();
    });
  };
}


//############# Upload Images ######################
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, path.join(__dirname, "../project_br/assets/images"));
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + "_" + file.originalname);
  }
});

const Upload = multer({
  storage, fileFilter: function (req, file, cb) {

    const allowedType = ['.png', '.jpg', '.jpeg'];
    const ext = path.extname(file.originalname).toLowerCase();

    if (!allowedType.includes(ext)) {
      return cb(new Error('Only .png, .jpg, .jpeg allowed'));
    }
    cb(null, true);
  },
  limits: { fileSize: 10 * 1024 * 1024 } // Max 10MB
});


// ================= AUTH ROUTES =================
app.post('/auth/login', (req, res) => {
  const { username, password } = req.body;
  const sql = "SELECT user_id, password, role FROM users WHERE username = ?";
  console.log("Received login request:", { username, password });
  con.query(sql, [username], function (err, results) {
    if (err) {
      console.error("Database query error:", err);
      return res.status(500).json({ message: 'Server error' });
    }
    if (results.length === 0) {
      return res.status(400).json({ message: 'Wrong username' });
    }
    const hash = results[0].password;
    const role = results[0].role;
    bcrypt.compare(password, hash, function (err, same) {
      if (err) {
        console.error("Password comparison error:", err);
        return res.status(500).json({ message: 'Hash error' });
      }
      if (!same) {
        return res.status(401).json({ message: 'Login fail' });
      }
      const token = jwt.sign(
        { id: results[0].user_id, username: username, role: role },
        JWT_KEY,
        { expiresIn: '5d' }
      );
      res.cookie('authToken', token, {
        maxAge: 1000 * 60 * 60 * 24 * 5, // 30 วัน
        httpOnly: true, // ปลอดภัยจากการถูกอ่านด้วย JS
        secure: false,  // true ถ้าใช้ HTTPS
        sameSite: 'lax'
      });
      res.json({ message: 'Login ok', user_id: results[0].user_id, role: role, token, username: username });
    });
  });
});


// Registration route
app.post('/auth/register', (req, res) => {
  const { username, password, email } = req.body;
  if (!username || !password || !email) {
    return res.status(400).json({ message: 'Username, email, and password are required' });
  }
  bcrypt.hash(password, 10, (err, hash) => {
    if (err) {
      return res.status(500).json({ message: 'Error hashing password' });
    }
    const sql = "INSERT INTO users (username, password, email, role) VALUES (?, ?, ?, 'Student')";
    con.query(sql, [username, hash, email], (err, result) => {
      if (err) {
        return res.status(500).json({ message: 'Database error' });
      }
      res.status(201).json({ message: 'User registered successfully!' });
    });
  });
});

// Logout route
app.post('/auth/logout', (req, res) => {
  res.clearCookie('authToken');
  res.json({ message: 'Logout successful' });
});

app.get('/auth/profile', (req, res) => {
  const token = req.cookies.authToken;
  if (!token) {
    return res.status(401).json({ success: false, message: 'Unauthorized: No token' });
  }
  jwt.verify(token, JWT_KEY, (err, decoded) => {
    if (err) {
      return res.status(403).json({ success: false, message: 'Invalid or expired token' });
    }
    res.json({
      success: true,
      message: 'Welcome to your profile',
      user: {
        id: decoded.id,
        username: decoded.username,
        role: decoded.role
      }
    });
  });
});

///=========================================================================
///========================= ROOM ROUTES ===================================
///=========================================================================

// GET Browse All rooms 
app.get('/rooms', (req, res) => {
  const roomsSql = 'SELECT room_id, room_name, room_description, room_status, capacity, image FROM rooms';
  con.query(roomsSql, (err, rooms) => {
    if (err) {
      return res.status(500).json({ error: 'Database server error' });
    }
    const bookingsSql = `
            SELECT room_id, slot_id 
            FROM bookings 
            WHERE booking_date = CURDATE()
            AND (booking_status = 'Pending' OR booking_status = 'approved')
        `;
    con.query(bookingsSql, (err, bookings) => {
      if (err) {
        return res.status(500).json({ error: 'Database server error' });
      }
      const finalRoomsData = rooms.map(room => {
        const matchingBookings = bookings.filter(booking => {
          return booking.room_id === room.room_id;
        });
        const booked_slots = matchingBookings.map(b => b.slot_id);
        return {
          ...room,
          booked_slots: booked_slots
        };
      });
      res.json(finalRoomsData);
    });
  });
});

// GET one room
app.get('/rooms/:id', (req, res) => {
  const roomId = req.params.id;
  const roomSql = 'SELECT room_id, room_name, room_description, room_status, capacity, image FROM rooms WHERE room_id = ?';
  con.query(roomSql, [roomId], (err, roomResult) => {
    if (err)
      return res.status(500).json({ error: err });
    if (roomResult.length === 0) {
      return res.status(404).json({ error: 'Room not found' });
    }
    const roomDetails = roomResult[0];
    const slotSql = `SELECT slot_id 
        FROM bookings 
        WHERE room_id = ?
        AND booking_date = CURDATE()
        AND (booking_status = 'Pending' OR booking_status = 'Approved')`;
    con.query(slotSql, [roomId], (err, slotResults) => {
      if (err)
        return res.status(500).json({ error: err });
      const bookedSlotIds = slotResults.map(row => row.slot_id);
      const finalRes = {
        ...roomDetails,
        booked_slots: bookedSlotIds
      }
      res.json(finalRes);
    });
  });
});

//########################### STAFF #############################################
// ADD NEW ROOM 
app.post(
  '/rooms',
  verifyAccess(['Staff']),
  Upload.single('image'),
  (req, res) => {
    const { room_name, capacity, room_description, room_status } = req.body;

    if (!req.file) {
      return res.status(400).json({ success: false, message: 'Image file is required' });
    }
    const image = req.file.filename;

    if (!room_name || !capacity || !room_description || !room_status) {
      return res.status(400).json({ success: false, message: 'Missing required fields' });
    }

    const checkSql = "SELECT room_id FROM rooms WHERE room_name = ?";

    con.query(checkSql, [room_name], (err, results) => {
      if (err) {
        console.error("Duplicate check error:", err);
        return res.status(500).json({ success: false, message: "Database query error" });
      }
      if (results.length > 0) {
        return res.status(409).json({ success: false, message: "This room name has already been inserted." });
      }
      const insertSql = `
        INSERT INTO rooms(room_name, capacity, room_description, image, room_status) 
        VALUES (?, ?, ?, ?, ?)
      `;

      con.query(insertSql, [room_name, capacity, room_description, image, room_status], (err, result) => {
        if (err) {
          console.error("Insert asset error:", err);
          return res.status(500).json({ success: false, message: "Database insert error" });
        }
        return res.status(200).json({ success: true, roomId: result.insertId });
      });
    });
  }
);
// EDIT ROOM 
app.put(
  '/rooms/:id',
  verifyAccess(['Staff']),
  Upload.single('image'),
  (req, res) => {
    const roomId = req.params.id;
    const { room_name, room_description, room_status, capacity } = req.body;

    if (!room_name || !room_description || !room_status || !capacity) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    let sql;
    let params;

    if (req.file) {
      const image = req.file.filename;
      sql = `
        UPDATE rooms 
        SET 
          room_name = ?, 
          room_description = ?, 
          room_status = ?,
          capacity = ?,
          image = ?
        WHERE room_id = ?
      `;
      params = [room_name, room_description, room_status, capacity, image, roomId];
    } else {
      sql = `
        UPDATE rooms 
        SET 
          room_name = ?, 
          room_description = ?, 
          room_status = ?,
          capacity = ?
        WHERE room_id = ?
      `;
      params = [room_name, room_description, room_status, capacity, roomId];
    }

    con.query(sql, params, (err, result) => {
      if (err) {
        console.error('Room Update Error:', err);
        return res.status(500).json({ error: 'Database update failed' });
      }
      if (result.affectedRows === 0) {
        return res.status(404).json({ error: 'Room not found' });
      }
      res.status(200).json({ message: 'Room updated successfully' });
    });
  }
);

///=========================================================================
///======================= BOOKING ROUTES ==================================
///=========================================================================

// GET Bookings for a user (History Page for ALL roles)
app.get('/bookings/user/:userId', verifyAccess(['Student', 'Lecturer', 'Staff']), (req, res) => {
  const userId = req.params.userId;
  const userRole = req.decoded.role.toLowerCase(); // Get role from the token

  let sql = '';
  let queryParams = [userId];

  if (userRole === 'student') {
    sql = `
      SELECT b.booking_id AS id, r.room_name, r.image, DATE_FORMAT(b.booking_date, '%Y-%m-%d') AS booking_date, b.slot_id,
      b.booking_status AS status, b.booking_reason AS reason, b.reject_reason AS lecturer_note,
      u_booked.username AS booked_by_name, u_approver.username AS approver_name,
      COALESCE(b.approved_on, b.rejected_on) AS action_date
      FROM bookings b
      JOIN rooms r ON b.room_id = r.room_id
      JOIN users u_booked ON b.user_id = u_booked.user_id
      LEFT JOIN users u_approver ON b.approved_by = u_approver.user_id
      WHERE b.user_id = ?
      ORDER BY b.booking_date DESC, b.slot_id ASC
    `;

  } else if (userRole === 'lecturer') {
    sql = `
      SELECT b.booking_id AS id, r.room_name, r.image, DATE_FORMAT(b.booking_date, '%Y-%m-%d') AS booking_date, b.slot_id,
      b.booking_status AS status, b.booking_reason AS reason, b.reject_reason AS lecturer_note,
      u_booked.username AS booked_by_name, u_approver.username AS approver_name,
      COALESCE(b.approved_on, b.rejected_on) AS action_date
      FROM bookings b
      JOIN rooms r ON b.room_id = r.room_id
      JOIN users u_booked ON b.user_id = u_booked.user_id
      LEFT JOIN users u_approver ON b.approved_by = u_approver.user_id
      WHERE b.approved_by = ?
      ORDER BY b.booking_date DESC, b.slot_id ASC
    `;

  } else if (userRole === 'staff') {
    sql = `
      SELECT b.booking_id AS id, r.room_name, r.image, DATE_FORMAT(b.booking_date, '%Y-%m-%d') AS booking_date, b.slot_id,
      b.booking_status AS status, b.booking_reason AS reason, b.reject_reason AS lecturer_note,
      u_booked.username AS booked_by_name, u_approver.username AS approver_name,
      COALESCE(b.approved_on, b.rejected_on) AS action_date
      FROM bookings b
      JOIN rooms r ON b.room_id = r.room_id
      JOIN users u_booked ON b.user_id = u_booked.user_id
      LEFT JOIN users u_approver ON b.approved_by = u_approver.user_id
      ORDER BY b.booking_date DESC, b.slot_id ASC
    `;
    queryParams = [];
  }

  // Execute the query
  con.query(sql, queryParams, (err, result) => {
    if (err) {
      return res.status(500).json({ error: "Database query failed", details: err.message });
    }
    res.json(result);
  });
});

// GET Today's Bookings for a user 
app.get('/bookings/user/:userId/today', (req, res) => {
  const userId = req.params.userId;
  const sql = `
    SELECT b.booking_id AS id, r.room_id, r.room_name, r.image, DATE_FORMAT(b.booking_date, '%Y-%m-%d') AS booking_date,
    b.slot_id, b.booking_status AS status, b.booking_reason AS reason, b.reject_reason AS lecturer_note,
    u_booked.username AS booked_by_name, u_approver.username AS approver_name,
    COALESCE(b.approved_on, b.rejected_on) AS action_date
    FROM bookings b
    JOIN rooms r ON b.room_id = r.room_id
    JOIN users u_booked ON b.user_id = u_booked.user_id
    LEFT JOIN users u_approver ON b.approved_by = u_approver.user_id
    WHERE b.user_id = ? 
    AND b.booking_date = CURDATE() 
    AND (b.booking_status = 'pending' OR b.booking_status = 'approved' OR b.booking_status = 'rejected')
    ORDER BY b.slot_id ASC
  `;
  con.query(sql, [userId], (err, result) => {
    if (err) {
      return res.status(500).json({ error: "Database query failed", details: err.message });
    }
    res.json(result);
  });
});

// CANCEL a booking (Any logged-in user)
app.put('/bookings/:id/cancel', verifyAccess(['Student']), (req, res) => {
  const bookingId = req.params.id;
  const selectSql = `SELECT room_id, slot_id FROM bookings WHERE booking_id = ?`;
  con.query(selectSql, [bookingId], (err, results) => {
    if (err) return res.status(500).json({ error: 'Database select failed' });
    if (results.length === 0) return res.status(404).json({ error: 'Booking not found' });
    const { room_id, slot_id } = results[0];
    const updateSql = `UPDATE bookings SET booking_status = 'Cancelled' WHERE booking_id = ?`;
    con.query(updateSql, [bookingId], (err) => {
      if (err) return res.status(500).json({ error: 'Booking update failed' });
      const releaseSql = `UPDATE rooms SET room_status = 'Free' WHERE room_id = ?`;
      con.query(releaseSql, [room_id], (err2) => {
        if (err2) return res.status(500).json({ error: 'Room update failed' });
        res.json({ message: 'Booking cancelled and room freed' });
      });
    });
  });
});

// CREATE a booking 
app.post('/bookings', verifyAccess(['Student']), (req, res) => {
  const { room_id, slot_id, booking_date, booking_reason } = req.body;
  const user_id = req.decoded ? req.decoded.id : null;
  if (!room_id || !slot_id || !booking_date || !user_id) {
    return res.status(400).json({ error: 'Missing required booking information.' });
  }
  const sql = "INSERT INTO bookings (room_id, slot_id, booking_date, booking_reason, user_id, booking_status) VALUES (?, ?, ?, ?, ?, 'Pending')";
  con.query(sql, [room_id, slot_id, booking_date, booking_reason || null, user_id], (err, result) => {
    if (err) {
      console.error('Booking Error:', err);
      return res.status(500).json({ error: 'Failed to create booking' });
    }
    res.status(200).json({ message: 'Booking request sent!', booking_id: result.insertId });
  });
});


// ================= LECTURER ROUTES =================
// Lecturer: pending requests list
app.get('/bookings/requests', verifyAccess(['Lecturer']), (req, res) => {
  con.query(
    `SELECT b.booking_id, b.booking_status, 
            CONVERT_TZ(b.booking_date, '+00:00', '+07:00') AS booking_date, 
            r.room_name, r.image AS room_image, 
            u.username AS user_name, 
            t.slot_name, t.start_time, t.end_time,
            b.booking_status AS status,
            b.slot_id,
            b.booking_reason AS reason,
            COALESCE(b.approved_on, b.rejected_on) AS action_date


     FROM bookings b 
     JOIN rooms r ON b.room_id = r.room_id 
     JOIN users u ON b.user_id = u.user_id 
     JOIN time_slots t ON b.slot_id = t.slot_id 
     WHERE LOWER(b.booking_status) = 'pending' 
     ORDER BY b.booking_id DESC`,
    (err, result) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json(result);
    }
  );
});

// Lecturer: approve
app.put('/bookings/:id/approve', verifyAccess(['Lecturer']), (req, res) => {
  con.query(
    "UPDATE bookings SET booking_status = 'approved', approved_by = ?, approved_on = NOW() WHERE booking_id = ? AND LOWER(booking_status) = 'pending'",
    [req.decoded.id, req.params.id],
    (err, result) => {
      if (err) return res.status(500).json({ error: 'Database error' });
      if (result.affectedRows === 0)
        return res.status(404).json({ message: 'Not found' });
      res.json({ message: 'Approved' });
    }
  );
});

// Lecturer: reject
app.put('/bookings/:id/reject', verifyAccess(['Lecturer']), (req, res) => {
  con.query(
    "UPDATE bookings SET booking_status = 'rejected', reject_reason = ?, approved_by = ?, rejected_on = NOW() WHERE booking_id = ? AND LOWER(booking_status) = 'pending'",
    [req.body.reject_reason, req.decoded.id, req.params.id],
    (err, result) => {
      if (err) return res.status(500).json({ error: err.message });
      if (result.affectedRows === 0)
        return res.status(404).json({ message: 'Not found' });
      res.json({ message: 'Rejected' });
    }
  );
});


//####################################### DASHBOARD #############################################
app.get('/dashboard/summary', verifyAccess(['Lecturer', 'Staff']), (req, res) => {
  con.query(
    `SELECT
        (SELECT COUNT(*) FROM rooms) * (SELECT COUNT(*) FROM time_slots) AS totalSlots,
        (SELECT COUNT(*) FROM rooms) * (SELECT COUNT(*) FROM time_slots) - (SELECT COUNT(*) FROM rooms WHERE room_status = 'disabled') * (SELECT COUNT(*) FROM time_slots) - (SELECT COUNT(*) FROM bookings WHERE LOWER(booking_status) = 'pending') - (SELECT COUNT(*) FROM bookings WHERE LOWER(booking_status) = 'approved'AND booking_date = CURDATE()) AS freeRooms,
        (SELECT COUNT(*) FROM rooms WHERE room_status = 'disabled') * (SELECT COUNT(*) FROM time_slots) AS disabledRooms,
        (SELECT COUNT(*) FROM bookings WHERE LOWER(booking_status) = 'pending') AS pendingBookings,
        (SELECT COUNT(*) FROM bookings WHERE LOWER(booking_status) = 'approved'AND booking_date = CURDATE()) AS reservedBookings`,
    (err, result) => {
      if (err) return res.status(500).json({ error: 'Database error' });
      res.json(result[0]);
    }
  );
});

///=========================================================================
// ---------- Server starts here ---------
// root service
// localhost:3000
const PORT = 3000;
app.listen(PORT, "0.0.0.0", () => {
  console.log('Server is running at ' + PORT);
});