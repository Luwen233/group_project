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
            res.status(401).send('Incorrect token');
        }
        else if (decoded.role != 'user') {
            res.status(403).send('Forbidden to access the data');
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

// Profile route to check cookie
app.get('/auth/profile', (req, res) => {
    const token = req.cookies.authToken;

    if (!token) {
        return res.status(401).json({ success: false, message: 'Unauthorized: No token' });
    }

    // ตรวจสอบ token ด้วย jwt.verify
    jwt.verify(token, JWT_KEY, (err, decoded) => {
        if (err) {
            return res.status(403).json({ success: false, message: 'Invalid or expired token' });
        }

        // ถอดรหัสสำเร็จ → ส่งข้อมูลผู้ใช้กลับไป
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
    const today = new Date().toISOString().split('T')[0];

    const roomsSql = 'SELECT room_id, room_name, room_description, room_status, capacity, image FROM rooms';

    con.query(roomsSql, (err, rooms) => {
        if (err) {
            console.error('[GET /rooms] (Query 1) error:', err);
            return res.status(500).json({ error: 'Database server error' });
        }

        //  GET ALL of today's booked slots ---
        const bookingsSql = `
            SELECT room_id, slot_id 
            FROM bookings 
            WHERE booking_date = ? 
            AND (booking_status = 'Pending' OR booking_status = 'Approved')
        `;

        con.query(bookingsSql, [today], (err, bookings) => {
            if (err) {
                console.error('[GET /rooms] (Query 2) error:', err);
                return res.status(500).json({ error: 'Database server error' });
            }
            //loop
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

// GET check if student has an active booking TODAY
app.get('/my-bookings-today/:userId', (req, res) => {
    const userId = req.params.userId;
    const today = new Date().toISOString().split('T')[0];

    const sql = `
        SELECT booking_id FROM bookings
        WHERE user_id = ? 
        AND booking_date = ? 
        AND (booking_status = 'Pending' OR booking_status = 'Approved')
    `;

    con.query(sql, [userId, today], (err, results) => {
        if (err) return res.status(500).json({ error: err });
        res.json(results);
    });
});



app.post('/rooms/:type', (req, res) => {

});

app.patch('/rooms/:id', (req, res) => {

});

app.patch('/rooms/:id/disable', (req, res) => {

});

///=========================================================================

app.get('/timeslots/', (req, res) => {

});

app.get('/timeslots/', (req, res) => {

});
///=========================================================================

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

app.get('/bookings', (req, res) => {

});

app.get('/bookings/:id', (req, res) => {

});

// app.patch('/bookings/:id/cancel', (req, res) => {
//     const bookingId = req.params.id;
//     const sql = "UPDATE bookings SET booking_status = 'Cancelled' WHERE booking_id = ?";

//     con.query(sql, [bookingId], (err, result) => {
//         if (err) return res.status(500).json({ error: err });
//         if (result.affectedRows === 0) {
//             return res.status(404).json({ error: 'Booking not found' });
//         }
//         res.json({ message: 'Booking cancelled' });
//     });
// });

app.get('/bookings/requests', (req, res) => {

});

app.patch('/bookings/:id/approve', (req, res) => {

});

app.patch('/bookings/reject', (req, res) => {

});

///=========================================================================

app.get('/logs', (req, res) => {
  const sql = 'SELECT * FROM booking_logs';
 con.query(sql, (err, results) => {
    if (err) {
      console.error(err);
      return res.status(500).json({ message: 'Database error' });
    }
    res.json(results);
  });
});

app.get('/logs/user/:id', (req, res) => {
  const userId = req.params.id;
  const sql = 'SELECT * FROM booking_logs WHERE booked_by = ? ORDER BY log_id ASC';
  db.query(sql, [userId], (err, results) => {
    if (err) {
      console.error(err);
      return res.status(500).json({ message: 'Database error' });
    }
    res.json(results);
  });
});

app.get('/logs/room/:id', (req, res) => {
  const roomId = req.params.id;
  const sql = 'SELECT * FROM booking_logs WHERE room_id = ? ORDER BY log_id ASC';
  db.query(sql, [roomId], (err, results) => {
    if (err) {
      console.error(err);
      return res.status(500).json({ message: 'Database error' });
    }
    res.json(results);
  });
});





///=========================================================================
// ---------- Server starts here ---------
// root service
// localhost:3000
const PORT = 3000;
app.listen(PORT, "0.0.0.0", () => {
    console.log('Server is running at ' + PORT);
});
