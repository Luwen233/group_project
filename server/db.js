require('dotenv').config();
const mysql = require("mysql2");

// ใช้ Connection Pool แทน Single Connection เพื่อประสิทธิภาพที่ดีขึ้น
const pool = mysql.createPool({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'booking_r',
    port: process.env.DB_PORT || 3307,
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
});

// ทดสอบการเชื่อมต่อเมื่อเริ่มต้น
pool.getConnection((err, connection) => {
    if (err) {
        console.error('🔴 MySQL Connection FAILED! ตรวจสอบ XAMPP/Port/รหัสผ่าน');
        console.error(err);
        return;
    }
    console.log('🟢 MySQL Connection Pool SUCCESSFUL!');
    connection.release();
});

// Export pool โดยตรง (ยังคงใช้ callback API เหมือนเดิม)
module.exports = pool;