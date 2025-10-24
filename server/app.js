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

            res.json({ message: 'Login ok', user_id: results[0].user_id, role: role, token });
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






///=========================================================================
// ---------- Server starts here ---------
// root service
// localhost:3000
const PORT = 3000;
app.listen(PORT, () => {
    console.log('Server is running at ' + PORT);
});
