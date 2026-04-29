var mysql = require('mysql');

var con = mysql.createConnection({
    host: "localhost",
    user: "root",
    password: "",
    database: "mydb5"
});

con.connect(function(err) {
    if (err) throw err;
    console.log("Connected!");

    var sql = "CREATE TABLE customers4 (name VARCHAR(255), address VARCHAR(255))";

    con.query(sql, function (err, result) {
        if (err) throw err;
        console.log("Table created");
    });
});
