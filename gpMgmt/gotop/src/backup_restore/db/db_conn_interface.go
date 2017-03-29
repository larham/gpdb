package db

import "database/sql"

type DbDriver interface {
	Open(driverName, dataSourceName string) (*sql.DB, error)
}

type DbConnection interface {
	Ping() error
	//Close() error
	Query(query string, args ...interface{}) (*sql.Rows, error)
}

type DbRows interface {
	Close() error
	Scan(dest ...interface{}) error
	Columns() ([]string, error)
	Next() bool
}
