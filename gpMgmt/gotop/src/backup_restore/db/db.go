package db

import (
	"database/sql"
	"fmt"
	"os"
	"os/user"
	"strconv"

	"backup_restore/utils"

	_ "github.com/lib/pq"
)

type DBConn struct {
	Driver DbDriver
	Conn   DbConnection
	User   string
	DBName string
	Host   string
	Port   int
}

func NewDBConn(dbname string, username string, port int, host string) *DBConn {
	default_user, _ := user.Current()
	default_host, _ := os.Hostname()
	username = utils.TryEnv("PGUSER", default_user.Username)
	dbname = utils.TryEnv("PGDATABASE", dbname)
	if dbname == "" {
		utils.Abort("No database provided and PGDATABASE not set")
	}
	host = utils.TryEnv("PGHOST", default_host)
	port, _ = strconv.Atoi(utils.TryEnv("PGPORT", "5432"))

	return &DBConn{
		Driver: RealDbDriver{},
		Conn:   nil,
		DBName: dbname,
		User:   username,
		Port:   port,
		Host:   host,
	}
}

func (dbconn *DBConn) Connect() error {
	connStr := fmt.Sprintf("user=%s dbname=%s host=%s port=%d sslmode=disable", dbconn.User, dbconn.DBName, dbconn.Host, dbconn.Port)
	var err error
	dbconn.Conn, err = dbconn.Driver.Open("postgres", connStr)
	if dbconn.Conn == nil {
		return err
	}
	err = dbconn.Conn.Ping()
	if err != nil {
		return err
	}
	return nil
}

func (dbconn *DBConn) GetRows(query string) ([][]interface{}, error) {
	fmt.Println("Got to getrows")
	rows, err := dbconn.Conn.Query(query)
	if err != nil {
		fmt.Println("got query failure")
		return nil, err
	}
	defer rows.Close()

	var results [][]interface{}
	cols, err := rows.Columns()
	if err != nil {
		return nil, err
	}
	vals := make([]interface{}, len(cols))

	for rows.Next() {
		row := make([]interface{}, len(cols))
		for i, _ := range cols {
			vals[i] = &row[i]
		}
		if err = rows.Scan(vals...); err != nil {
			return nil, err
		}
		for i, datum := range row {
			test, ok := datum.([]byte)
			if ok {
				row[i] = string(test)
			}
		}
		results = append(results, row)
	}
	return results, nil
}

type RealDbDriver struct{}

func (driver RealDbDriver) Open(driverName, dataSourceName string) (*sql.DB, error) {
	db, err := sql.Open(driverName, dataSourceName)
	if err != nil {
		return nil, err
	}
	//realDbConn := RealDbConnection{
	//	dbConnection: db,
	//}
	return db, nil
}

type RealDbConnection struct {
	dbConnection *sql.DB
}

//func (db *RealDbConnection) Close() error {}
func (db RealDbConnection) Ping() error {
	return db.dbConnection.Ping()
}
func (db RealDbConnection) Query(query string, args ...interface{}) (DbRows, error) {
	return db.dbConnection.Query(query, args)
}
