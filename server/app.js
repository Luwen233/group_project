const express = require('express');
const app = express();
const bcrypt = require('bcrypt');
const con = require('./db'); // Database connection
const jwt = require('jsonwebtoken');
const cookieParser = require('cookie-parser');

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cookieParser());


const JWT_KEY = 'm0bile2Simple';


// ================= Middleware ================
function verifyUser(req, res, next) {
  let token = req.headers['authorization'] || req.headers['x-access-token'];
  if (token == undefined || token == null) {
    // no token
    return res.status(400).send('No token');
  }

  // token found
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

    else {
      req.decoded = decoded;
      next();
    }
  });
}

// Login route
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
  console.log("Received registration request:", { username, email });

  if (!username || !password || !email) {
    console.error("Registration error: Username, email, and password are required");
    return res.status(400).json({ message: 'Username, email, and password are required' });
  }

  bcrypt.hash(password, 10, (err, hash) => {
    if (err) {
      console.error("Error hashing password:", err);
      return res.status(500).json({ message: 'Error hashing password' });
    }

    const sql = "INSERT INTO users (username, password, email, role) VALUES (?, ?, ?, 'Student')";
    con.query(sql, [username, hash, email], (err, result) => {
      if (err) {
        console.error("Database error during registration:", err);
        return res.status(500).json({ message: 'Database error' });
      }

      console.log("User registered successfully:", { username, email });
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
// GET Browse All rooms
app.get('/rooms', (req, res) => {

  const roomsSql = 'SELECT room_id, room_name, room_description, room_status, capacity, image FROM rooms';

  con.query(roomsSql, (err, rooms) => {
    if (err) {
      console.error('[GET /rooms] (Query 1) error:', err);
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
        console.error('[GET /rooms] (Query 2) error:', err);
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

app.get('/bookings/user', verifyUser, (req, res) => {
  const decoded = req.decoded;
  let sql = '';

  if (decoded.role == 'Student')
    sql = `
      SELECT 
        b.booking_id AS id,
        r.room_name,
        r.image,
        DATE_FORMAT(b.booking_date, '%Y-%m-%d') AS booking_date,
        b.slot_id, 
        b.booking_status AS status,
        b.booking_reason AS reason,
        b.reject_reason AS lecturer_note,
        u_booked.username AS booked_by_name,
        u_approver.username AS approver_name,
        COALESCE(b.approved_on, b.rejected_on) AS action_date

      FROM bookings b
      JOIN rooms r ON b.room_id = r.room_id
      JOIN users u_booked ON b.user_id = u_booked.user_id
      LEFT JOIN users u_approver ON b.approved_by = u_approver.user_id
      WHERE b.user_id = ?  
      ORDER BY b.booking_date DESC, b.slot_id ASC
    `;
  else
    sql = `
      SELECT 
        b.booking_id AS id,
        r.room_name, r.image, DATE_FORMAT(b.booking_date, '%Y-%m-%d') AS booking_date, b.slot_id, 
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

  con.query(sql, [decoded.id], (err, result) => {
    if (err) {
      console.error("DB error:", err);
      return res.status(500).json({ error: "Database query failed", details: err.message });
    }
    res.json(result);
  });
});

app.get('/bookings/user/:userId/today', (req, res) => {
  const userId = req.params.userId;

  const sql = `
  SELECT 
    b.booking_id AS id,
    r.room_id,
    r.room_name,
    r.image,
    DATE_FORMAT(b.booking_date, '%Y-%m-%d') AS booking_date,
    b.slot_id, 
    b.booking_status AS status,
    b.booking_reason AS reason,
    b.reject_reason AS lecturer_note,
    u_booked.username AS booked_by_name,
    u_approver.username AS approver_name,
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
      console.error("DB error:", err);
      return res.status(500).json({ error: "Database query failed", details: err.message });
    }
    res.json(result);
  });
});


app.patch('/bookings/:id/cancel', (req, res) => {
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

app.post('/bookings', verifyUser, (req, res) => {
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

// Lecturer: pending requests list
app.get('/bookings/requests', (req, res) => {
  con.query(
    `SELECT b.booking_id, b.booking_status, 
            CONVERT_TZ(b.booking_date, '+00:00', '+07:00') AS booking_date, 
            r.room_name, r.image AS room_image, 
            u.username AS user_name, 
            t.slot_name, t.start_time, t.end_time 
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
app.patch('/bookings/:id/approve', verifyUser, (req, res) => {
  if (req.decoded.role !== 'Lecturer' && req.decoded.role !== 'Staff') 
    return res.status(403).json({ message: 'Forbidden' });

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
app.patch('/bookings/:id/reject', verifyUser, (req, res) => {
  if (req.decoded.role !== 'Lecturer' && req.decoded.role !== 'Staff')
    return res.status(403).json({ message: 'Forbidden' });

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

app.get('/dashboard/summary', (req, res) => {
  con.query(
    `SELECT
        (SELECT COUNT(*) FROM rooms WHERE room_status = 'free') AS freeRooms,
        (SELECT COUNT(*) FROM rooms WHERE room_status = 'disabled') AS disabledRooms,
        (SELECT COUNT(*) FROM bookings WHERE LOWER(booking_status) = 'pending') AS pendingBookings,
        (SELECT COUNT(*) FROM bookings WHERE LOWER(booking_status) = 'approved') AS reservedBookings`,
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