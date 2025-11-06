console.log("===== 🟢 TEST: โค้ดใหม่ v3 ทำงานแล้ว 🟢 =====");
require('dotenv').config();
const express = require('express');
const app = express();
const bcrypt = require('bcrypt');
const con = require('./db'); 
const jwt = require('jsonwebtoken');
const cookieParser = require('cookie-parser');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const { body, validationResult } = require('express-validator');

// ใช้ JWT_KEY จาก environment variable
const JWT_KEY = process.env.JWT_SECRET || 'm0bile2Simple';

// CORS Configuration
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cookieParser());

// Rate Limiting สำหรับป้องกัน Brute Force
const loginLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 นาที
    max: 5, // จำกัด 5 ครั้งต่อ IP
    message: 'Too many login attempts, please try again after 15 minutes'
});

const generalLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 100 // จำกัด 100 requests ต่อ 15 นาที
});

app.use(generalLimiter);

// ================= Middleware ================
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

// ================= AUTH ======================
app.post('/auth/login', 
    loginLimiter,
    [
        body('username').trim().notEmpty().withMessage('Username is required'),
        body('password').notEmpty().withMessage('Password is required')
    ],
    (req, res) => {
        // ตรวจสอบ validation errors
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ message: 'Invalid input', errors: errors.array() });
        }

        const { username, password } = req.body;
        const sql = "SELECT user_id, password, role FROM users WHERE username = ?";
        
        con.query(sql, [username], function (err, results) {
        if (err) {
            console.error("[POST /auth/login] DB Query Error:", err); // เพิ่ม Log
            return res.status(500).json({ message: 'Server error' });
        }
        if (results.length === 0) return res.status(400).json({ message: 'Wrong username' });

        const hash = results[0].password;
        const role = results[0].role;

        bcrypt.compare(password, hash, function (err, same) {
            if (!same) return res.status(401).json({ message: 'Login fail' });

            const token = jwt.sign({ id: results[0].user_id, username, role }, JWT_KEY, { expiresIn: '5d' });

            res.json({ message: 'Login ok', user_id: results[0].user_id, role, token, username });
        });
    });
});

app.post('/auth/register',
    [
        body('username').trim().isLength({ min: 3 }).withMessage('Username must be at least 3 characters'),
        body('email').isEmail().withMessage('Invalid email format'),
        body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters')
    ],
    (req, res) => {
        // ตรวจสอบ validation errors
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ message: 'Invalid input', errors: errors.array() });
        }

        const { username, password, email } = req.body;

        bcrypt.hash(password, 10, (err, hash) => {
        const sql = "INSERT INTO users (username, password, email, role) VALUES (?, ?, ?, 'Student')";
        con.query(sql, [username, hash, email], (dbErr) => {
            if (dbErr) {
                console.error("[POST /auth/register] DB Error:", dbErr);
                return res.status(500).json({ message: 'Registration failed due to server error' });
            }
            res.status(201).json({ message: 'Registered' });
        });
    });
});

// =============== GET Rooms ===================
app.get('/rooms', (req, res) => {
    const today = new Date().toISOString().split('T')[0];

    const roomsSql = 'SELECT room_id, room_name, room_description, room_status, capacity, image FROM rooms';

    con.query(roomsSql, (err, rooms) => {
        if (err) return res.status(500).json({ error: 'Database error' });

        const bookingsSql = `
            SELECT room_id, slot_id 
            FROM bookings 
            WHERE booking_date = ? 
            AND (booking_status = 'Pending' OR booking_status = 'Approved')
        `;

        con.query(bookingsSql, [today], (err, bookings) => {
            if (err) return res.status(500).json({ error: 'Database error' });

            const finalRoomsData = rooms.map(room => {
                const booked = bookings.filter(b => b.room_id === room.room_id).map(b => b.slot_id);
                return { ...room, booked_slots: booked };
            });
            res.json(finalRoomsData);
        });
    });
});

// ⭐️ [รวมโค้ด] เพิ่ม /rooms/:id
app.get('/rooms/:id', (req, res) => {
    const roomId = req.params.id;
    const today = new Date().toISOString().split('T')[0];

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
        AND booking_date = ?
        AND (booking_status = 'Pending' OR booking_status = 'Approved')`;

        con.query(slotSql, [roomId, today], (err, slotResults) => {
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

// =============== Student Active Booking Check ===================
app.get('/my-bookings-today/:userId', (req, res) => {
    const userId = req.params.userId;
    const today = new Date().toISOString().split('T')[0];

    const sql = `
        SELECT booking_id 
        FROM bookings
        WHERE user_id = ? 
        AND booking_date = ? 
        AND (booking_status = 'Pending' OR booking_status = 'Approved')
    `;

    con.query(sql, [userId, today], (err, results) => {
        if (err) return res.status(500).json({ error: err });
        res.json(results);
    });
});

// =============== BOOKING REQUEST LIST (Lecturer) ===================
app.get('/bookings/requests', (req, res) => {
  const sql = `
      SELECT 
          b.booking_id,
          b.booking_status, 
          CONVERT_TZ(b.booking_date, '+00:00', '+07:00') AS booking_date,
          r.room_name,
          r.image AS room_image,
          u.username AS user_name,
          t.slot_name,
          t.start_time,
          t.end_time
      FROM bookings b
      JOIN rooms r ON b.room_id = r.room_id
      JOIN users u ON b.user_id = u.user_id
      JOIN time_slots t ON b.slot_id = t.slot_id
      WHERE LOWER(b.booking_status) = 'pending'
      ORDER BY b.booking_id DESC;
  `;

  con.query(sql, (err, result) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(result);
  });
});
// =============== APPROVE ===================
app.patch('/bookings/:id/approve', verifyUser, (req, res) => {
    const bookingId = req.params.id;
    const lecturerId = req.decoded.id; 

    if (req.decoded.role !== 'Lecturer') {
         return res.status(403).json({ message: 'Forbidden: Only lecturers can approve' });
    }

    const sql = `
        UPDATE bookings 
        SET 
            booking_status = 'approved', 
            approved_by = ?
        WHERE 
            booking_id = ? AND booking_status = 'pending'
    `;

    con.query(sql, [lecturerId, bookingId], (err, result) => {
        if (err) {
            console.error(`[PATCH /bookings/${bookingId}/approve] DB Error:`, err);
            return res.status(500).json({ error: 'Database error' });
        }
        
        if (result.affectedRows === 0) {
            console.warn(`[PATCH /bookings/${bookingId}/approve] No rows affected.`);
            return res.status(404).json({ message: 'Booking not found or already processed' });
        }

        console.log(`[DB] Approved booking ${bookingId} by lecturer ${lecturerId}.`);
        const logSql = `
            INSERT INTO booking_logs (booking_id, room_id, slot_id, booked_by, action, approved_by, timestamp)
            SELECT b.booking_id, b.room_id, b.slot_id, b.user_id, 'approved', ?, NOW()
            FROM bookings b WHERE b.booking_id = ?
        `;
        
        con.query(logSql, [lecturerId, bookingId], (logErr) => {
            if (logErr) {
                 console.error(`[PATCH /bookings/${bookingId}/approve] LOG Error:`, logErr);
            }
            return res.json({ message: "Approved" });
        });
    });
});
// =============== REJECT ===================
app.patch('/bookings/:id/reject', verifyUser, (req, res) => {
    const bookingId = req.params.id;
    const reason = req.body.reject_reason || null;
    
    const lecturerId = req.decoded.id; 

    if (req.decoded.role !== 'Lecturer') {
         return res.status(403).json({ message: 'Forbidden: Only lecturers can reject' });
    }

    console.log(`[PATCH /bookings/${bookingId}/reject] REQ received. Reason: ${reason}`);

    const sql = `
        UPDATE bookings 
        SET 
            booking_status = 'rejected', 
            reject_reason = ?
        WHERE 
            booking_id = ? 
            AND booking_status = 'pending'
    `;

    con.query(sql, [reason, bookingId], (err, result) => {
        if (err) {
            console.error(`[PATCH /bookings/${bookingId}/reject] DB Error:`, err);
            return res.status(500).json({ error: err.message });
        }

        if (result.affectedRows === 0) {
            console.warn(`[PATCH /bookings/${bookingId}/reject] No rows affected.`);
            return res.status(404).json({ message: 'Booking not found or already processed' });
        } 

        console.log(`[DB] Rejected booking ${bookingId} by lecturer ${lecturerId}.`);
        
        const logSql = `
            INSERT INTO booking_logs (booking_id, room_id, slot_id, booked_by, action, approved_by, timestamp)
            SELECT b.booking_id, b.room_id, b.slot_id, b.user_id, 'rejected', ?, NOW()
            FROM bookings b 
            WHERE b.booking_id = ?
            ON DUPLICATE KEY UPDATE action = 'rejected', timestamp = NOW()`;
        
        con.query(logSql, [lecturerId, bookingId], (logErr) => {
            if (logErr) {
                 console.error(`[PATCH /bookings/${bookingId}/reject] LOG Error:`, logErr);
            }
            return res.json({ message: "Rejected" });
        });
    });
});
// =============== HISTORY (Lecturer) ===================
app.get('/bookings/history', (req, res) => {
  const sql = `
    SELECT 
        l.log_id,
        l.booking_id,
        CONVERT_TZ(l.timestamp, '+00:00', '+07:00') AS timestamp,
        l.action,
        r.room_name,
        r.image AS room_image,
        t.slot_name,
        b.booking_date, 
        b.reject_reason,
        u.username AS booked_by,
        a.username AS approved_by
    FROM booking_logs l
    JOIN rooms r ON l.room_id = r.room_id
    JOIN time_slots t ON l.slot_id = t.slot_id
    JOIN users u ON l.booked_by = u.user_id
    JOIN bookings b ON l.booking_id = b.booking_id
    LEFT JOIN users a ON l.approved_by = a.user_id
    ORDER BY l.timestamp DESC
  `;
  con.query(sql, (err, result) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(result || []);
  });
});

// =============== DASHBOARD ===================
app.get('/dashboard/summary', (req, res) => {
    const sql = `
        SELECT
            (SELECT COUNT(*) FROM rooms WHERE room_status = 'free') AS freeRooms,
            (SELECT COUNT(*) FROM rooms WHERE room_status = 'disabled') AS disabledRooms,
            (SELECT COUNT(*) FROM bookings WHERE booking_status = 'pending') AS pendingBookings,
            (SELECT COUNT(*) FROM bookings WHERE booking_status = 'approved') AS reservedBookings
    `;

    con.query(sql, (err, result) => {
        if (err) {
            console.error("[GET /dashboard/summary] Error:", err);
            return res.status(500).json({ error: 'Database error' });
        }
        return res.json(result[0]);
    });
});

// Start Server
const PORT = process.env.PORT || 3000;
// ใช้ 0.0.0.0 เพื่อให้ Android Emulator (10.0.2.2) เข้าถึงได้
app.listen(PORT, "0.0.0.0", () => {
    console.log(`🚀 Server running on port ${PORT}`);
    console.log(`📍 Environment: ${process.env.NODE_ENV || 'development'}`);
});