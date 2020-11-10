#!/usr/bin/expect -f

set timeout 2

set root_pass [lindex $argv 0]

spawn sudo mysql 
expect {
    "mysql>*" { 
        send -- "SET GLOBAL validate_password.policy = 0; SET GLOBAL validate_password.length = 6; SET GLOBAL validate_password.number_count = 0;\r" 
        send -- "DROP USER 'root'@'localhost'; CREATE USER 'root'@'%' IDENTIFIED BY 'qweqwe'; GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION; FLUSH PRIVILEGES;"
    }
}

exit

spawn sudo mysql_secure_installation
expect {
    "*VALIDATE PASSWORD*" { send -- "n\r" }
}
expect {
    "*New password:" { send -- "$root_pass\r" }
}
expect {
    "*Re-enter new password:" { send -- "$root_pass\r" }
}
expect "Do you wish to continue with the password provided?*"
send -- "y\r"
expect "Remove anonymous users?"
send -- "y\r"
expect "Disallow root login remotely?"
send -- "n\r"
expect "Remove test database and access to it?"
send -- "y\r"
expect "Reload privilege tables now?"
send -- "y\r"

spawn echo "===> Your mysql pass: $root_pass"

expect eof
