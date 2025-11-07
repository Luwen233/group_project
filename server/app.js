// server.js
console.log('=====  Server v4 =====');
const express = require('express');
const app = express();
const bcrypt = require('bcrypt');
const createPool = require('./db');
const dbConfig = {
  host: 'localhost',
  user: 'root',
  password: '',
  database: 'booking_r',
  port: 3306
};
const con = createPool(dbConfig); // สร้าง pool ด้วย config ที่กำหนดเอง
const jwt = require('jsonwebtoken');
const cookieParser = require('cookie-parser');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const { body, validationResult } = require('express-validator');

const JWT_KEY = process.env.JWT_SECRET || 'm0bile2Simple';

// Middlewares
app.use(cors()); // ถ้าต้องการ cookie/credential ให้ตั้ง { origin: true, credentials: true }
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cookieParser());

// Rate limiters
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  message: 'Too many login attempts'
});

const generalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100
});

app.use(generalLimiter);

// Auth middleware
function verifyUser(req, res, next) {
  let token = req.headers['authorization'] || req.headers['x-access-token'];
  if (!token) return res.status(400).send('No token');
  if (req.headers.authorization) {
    const tokenString = token.split(' ');
    if (tokenString[0] === 'Bearer') token = tokenString[1];
  }
  jwt.verify(token, JWT_KEY, (err, decoded) => {
    if (err) return res.status(401).send('Incorrect token');
    req.decoded = decoded;
    next();
  });
}

// Auth: login
app.post(
  '/auth/login',
  loginLimiter,
  [body('username').trim().notEmpty(), body('password').notEmpty()],
  (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty())
      return res.status(400).json({ message: 'Invalid input' });

    const { username, password } = req.body;
    con.query(
      'SELECT user_id, password, role FROM users WHERE username = ?',
      [username],
      (err, results) => {
        if (err) return res.status(500).json({ message: 'Server error' });
        if (results.length === 0)
          return res.status(400).json({ message: 'Wrong username' });

        bcrypt.compare(password, results[0].password, (err, same) => {
          if (!same) return res.status(401).json({ message: 'Login fail' });
          const token = jwt.sign(
            { id: results[0].user_id, username, role: results[0].role },
            JWT_KEY,
            { expiresIn: '5d' }
          );
          res.json({
            message: 'Login ok',
            user_id: results[0].user_id,
            role: results[0].role,
            token,
            username
          });
        });
      }
    );
  }
);

// Auth: register
app.post(
  '/auth/register',
  [
    body('username').trim().isLength({ min: 3 }),
    body('email').isEmail(),
    body('password').isLength({ min: 6 })
  ],
  (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty())
      return res.status(400).json({ message: 'Invalid input' });

    const { username, password, email } = req.body;
    bcrypt.hash(password, 10, (err, hash) => {
      con.query(
        "INSERT INTO users (username, password, email, role) VALUES (?, ?, ?, 'Student')",
        [username, hash, email],
        dbErr => {
          if (dbErr) return res.status(500).json({ message: 'Registration failed' });
          res.status(201).json({ message: 'Registered' });
        }
      );
    });
  }
);

// Helpers
const todayBangkok = () =>
  new Date(Date.now() + 7 * 60 * 60 * 1000).toISOString().split('T')[0];

// Rooms: list
app.get('/rooms', (req, res) => {
  const today = todayBangkok();
  con.query(
    'SELECT room_id, room_name, room_description, room_status, capacity, image FROM rooms',
    (err, rooms) => {
      if (err) return res.status(500).json({ error: 'Database error' });
      con.query(
        `SELECT room_id, slot_id 
         FROM bookings 
         WHERE booking_date = ? AND LOWER(booking_status) IN ('pending','approved')`,
        [today],
        (err, bookings) => {
          if (err) return res.status(500).json({ error: 'Database error' });
          const finalRoomsData = rooms.map(room => ({
            ...room,
            image: room.image && room.image.startsWith('assets/') ? room.image : `assets/images/${room.image || 'room1.jpg'}`,
            booked_slots: bookings
              .filter(b => b.room_id === room.room_id)
              .map(b => b.slot_id)
          }));
          res.json(finalRoomsData);
        }
      );
    }
  );
});

// Rooms: detail with booked slots today
app.get('/rooms/:id', (req, res) => {
  const today = todayBangkok();
  con.query(
    'SELECT * FROM rooms WHERE room_id = ?',
    [req.params.id],
    (err, roomResult) => {
      if (err || roomResult.length === 0)
        return res.status(404).json({ error: 'Room not found' });
      con.query(
        `SELECT slot_id 
         FROM bookings 
         WHERE room_id = ? AND booking_date = ? 
           AND LOWER(booking_status) IN ('pending','approved')`,
        [req.params.id, today],
        (err, slotResults) => {
          if (err) return res.status(500).json({ error: 'Database error' });
          const room = roomResult[0];
          const image = room.image && room.image.startsWith('assets/') ? room.image : `assets/images/${room.image || 'room1.jpg'}`;
          res.json({
            ...room,
            image,
            booked_slots: slotResults.map(r => r.slot_id)
          });
        }
      );
    }
  );
});

// My bookings today (ids)
app.get('/my-bookings-today/:userId', (req, res) => {
  const today = todayBangkok();
  con.query(
    `SELECT booking_id 
     FROM bookings 
     WHERE user_id = ? AND booking_date = ? 
       AND LOWER(booking_status) IN ('pending','approved')`,
    [req.params.userId, today],
    (err, results) => {
      if (err) return res.status(500).json({ error: err });
      res.json(results);
    }
  );
});

// Check if user already has booking today
app.get('/bookings/user/:userId/today', (req, res) => {
  const today = todayBangkok();
  con.query(
    `SELECT COUNT(*) as count 
     FROM bookings 
     WHERE user_id = ? AND booking_date = ? 
       AND LOWER(booking_status) IN ('pending','approved')`,
    [req.params.userId, today],
    (err, results) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ hasBooking: results[0].count > 0 });
    }
  );
});

// User pending bookings
app.get('/bookings/user/:userId/pending', (req, res) => {
  con.query(
    `SELECT b.booking_id, b.room_id, b.slot_id, b.booking_status, 
            CONVERT_TZ(b.booking_date, '+00:00', '+07:00') AS booking_date, 
            r.room_name, r.image AS room_image, r.capacity, 
            t.slot_name, t.start_time, t.end_time 
     FROM bookings b 
     JOIN rooms r ON b.room_id = r.room_id 
     JOIN time_slots t ON b.slot_id = t.slot_id 
     WHERE b.user_id = ? AND LOWER(b.booking_status) = 'pending' 
     ORDER BY b.booking_date DESC, t.start_time ASC`,
    [req.params.userId],
    (err, results) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json(results || []);
    }
  );
});

// User history (case-insensitive)
app.get('/bookings/user/:userId/history', verifyUser, (req, res) => {
  con.query(
    `SELECT b.booking_id, b.room_id, b.slot_id, 
            b.booking_status AS status, 
            CONVERT_TZ(b.booking_date, '+00:00', '+07:00') AS booking_date,
            b.reject_reason,
            r.room_name, r.image AS room_image, r.capacity, 
            t.slot_name, t.start_time, t.end_time,
            u.username AS booked_by_name,
            a.username AS approved_by_name,  -- ✅ แก้ตรงนี้
            CONVERT_TZ(b.booking_date, '+00:00', '+07:00') AS action_date
     FROM bookings b 
     JOIN rooms r ON b.room_id = r.room_id 
     JOIN time_slots t ON b.slot_id = t.slot_id 
     JOIN users u ON b.user_id = u.user_id
     LEFT JOIN users a ON b.approved_by = a.user_id
     WHERE b.user_id = ?
       AND LOWER(b.booking_status) IN ('approved','rejected','cancelled')
     ORDER BY b.booking_date DESC, t.start_time DESC`,
    [req.params.userId],
    (err, results) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json(results || []);
    }
  );
});
// Create booking
app.post(
  '/bookings',
  verifyUser,
  [body('room_id').isInt(), body('slot_id').isInt(), body('booking_date').isDate()],
  (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty())
      return res
        .status(400)
        .json({ message: 'Invalid input', errors: errors.array() });

    const { room_id, slot_id, booking_date } = req.body;
    const user_id = req.decoded.id;

    const today = todayBangkok();
    // Check existing booking today for this user
    con.query(
      `SELECT COUNT(*) as count 
       FROM bookings 
       WHERE user_id = ? AND booking_date = ? 
         AND LOWER(booking_status) IN ('pending','approved')`,
      [user_id, today],
      (err, checkResults) => {
        if (err)
          return res
            .status(500)
            .json({ message: 'Database error', error: err.message });

        if (checkResults[0].count > 0) {
          return res.status(400).json({ message: 'คุณมีการจองในวันนี้แล้ว' });
        }

        // Check slot availability for selected date/room/slot
        con.query(
          `SELECT COUNT(*) as count 
           FROM bookings 
           WHERE room_id = ? AND slot_id = ? AND booking_date = ? 
             AND LOWER(booking_status) IN ('pending','approved')`,
          [room_id, slot_id, booking_date],
          (err, slotCheck) => {
            if (err)
              return res
                .status(500)
                .json({ message: 'Database error', error: err.message });

            if (slotCheck[0].count > 0) {
              return res
                .status(400)
                .json({ message: 'ช่วงเวลานี้ถูกจองแล้ว' });
            }

            // Create booking
            con.query(
              `INSERT INTO bookings (user_id, room_id, slot_id, booking_date, booking_status) 
               VALUES (?, ?, ?, ?, 'pending')`,
              [user_id, room_id, slot_id, booking_date],
              (err, result) => {
                if (err)
                  return res
                    .status(500)
                    .json({
                      message: 'Failed to create booking',
                      error: err.message
                    });

                res.status(201).json({
                  booking_id: result.insertId,
                  message: 'จองสำเร็จ รอการอนุมัติ'
                });
              }
            );
          }
        );
      }
    );
  }
);

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
    "UPDATE bookings SET booking_status = 'rejected', reject_reason = ?, rejected_on = NOW() WHERE booking_id = ? AND LOWER(booking_status) = 'pending'",
    [req.body.reject_reason, req.params.id],
    (err, result) => {
      if (err) return res.status(500).json({ error: err.message });
      if (result.affectedRows === 0)
        return res.status(404).json({ message: 'Not found' });

      res.json({ message: 'Rejected' });
    }
  );
});

// User: cancel own pending booking
app.patch('/bookings/:id/cancel', verifyUser, (req, res) => {
  const bookingId = req.params.id;
  const userId = req.decoded.id;

  con.query(
    "UPDATE bookings SET booking_status = 'cancelled' WHERE booking_id = ? AND user_id = ? AND LOWER(booking_status) = 'pending'",
    [bookingId, userId],
    (err, result) => {
      if (err) return res.status(500).json({ error: err.message });
      if (result.affectedRows === 0) {
        return res
          .status(404)
          .json({ message: 'Booking not found or cannot be cancelled' });
      }

      res.json({ message: 'Booking cancelled successfully' });
    }
  );
});

// Global history (admin/reference)
app.get('/bookings/history', (req, res) => {
  con.query(
    `SELECT b.booking_id, 
            r.room_name, 
            r.image AS room_image, 
            t.slot_name, 
            CONVERT_TZ(b.booking_date, '+00:00', '+07:00') AS booking_date, 
            b.booking_status AS action,
            CONVERT_TZ(
              CASE 
                WHEN LOWER(b.booking_status) = 'approved' THEN b.approved_on
                WHEN LOWER(b.booking_status) = 'rejected' THEN b.rejected_on
                ELSE b.booking_date
              END, '+00:00', '+07:00'
            ) AS timestamp,
            b.reject_reason, 
            u.username AS booked_by,     -- ✅ u = คนจอง
            a.username AS approved_by    -- ✅ a = คนอนุมัติ
     FROM bookings b
     JOIN rooms r ON b.room_id = r.room_id 
     JOIN time_slots t ON b.slot_id = t.slot_id 
     JOIN users u ON b.user_id = u.user_id 
     LEFT JOIN users a ON b.approved_by = a.user_id  -- ✅ เพิ่มบรรทัดนี้
     WHERE LOWER(b.booking_status) IN ('approved','rejected','cancelled')
     ORDER BY timestamp DESC`,
    (err, result) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json(result || []);
    }
  );
});
// Dashboard summary
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

// 404 fallback
app.use((req, res) => {
  res.status(404).json({ message: 'Not found' });
});

// Global error handler (optional centralized)
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({ message: 'Internal server error' });
});

// Start server
const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server running on port ${PORT}`);
});