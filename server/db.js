// db.js
const mysql = require("mysql2");

function createPool(config) {
    const pool = mysql.createPool({
        host: config.host || 'localhost',
        user: config.user || 'root',
        password: config.password || '',
        database: config.database || 'booking_r',
        port: config.port || 3306,
        timezone: '+07:00',
        waitForConnections: true,
        connectionLimit: 10,
        queueLimit: 0
    });

    pool.getConnection((err, connection) => {
        if (err) {
            console.error('🔴 MySQL Connection FAILED! ตรวจสอบ XAMPP/Port/รหัสผ่าน');
            console.error(err);
            return;
        }
        console.log('🟢 MySQL Connection Pool SUCCESSFUL!');
        connection.release();
    });
    return pool;
}

module.exports = createPool;
