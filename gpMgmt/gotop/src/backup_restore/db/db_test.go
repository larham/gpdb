package db_test

import (
	"fmt"

	"backup_restore/db"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"

	"database/sql"

	"gopkg.in/DATA-DOG/go-sqlmock.v1"
)

var _ = Describe("DBConn", func() {

	var (
		subject *db.DBConn
	)

	BeforeEach(func() {
		subject = db.NewDBConn("gptest", "", 0, "asdfa")
		subject.Driver = FakeDbDriver{}
	})

	Describe("happy path: a database is ready", func() {
		It("it connects to database", func() {
			// setup

			err := subject.Connect()
			Expect(err).NotTo(HaveOccurred())
			//mock.ExpectQuery("select schemaname,tablename from pg_table").WillReturnRows(sqlmock.NewResult(1, 1))

			rows, err := subject.GetRows("select schemaname,tablename from pg_tables")
			Expect(err).NotTo(HaveOccurred())
			Expect(len(rows)).To(Equal(3))

			for _, datum := range rows {
				fmt.Printf("The schema for table %s is %s\n", datum[1], datum[0])
			}

		})
	})
})

type FakeDbDriver struct {
	mock sqlmock.Sqlmock
}

func (driver FakeDbDriver) Open(driverName, dataSourceName string) (*sql.DB, error) {
	dbConnection, mock, _ := sqlmock.New()
	driver.mock = mock

	//mock.ExpectQuery("select schemaname,tablename from pg_table").WillReturnRows(sqlmock.NewResult(1, 1))
	return dbConnection, nil
}

type FakeDbConnection struct{}

//func (db *RealDbConnection) Close() error {}
func (db FakeDbConnection) Ping() error {
	return nil
}

func (db FakeDbConnection) Query(query string, args ...interface{}) (db.DbRows, error) {
	fakeRows := FakeDbRows{
		Names:  make([]string, 2),
		Values: make([]string, 2),
	}

	//fakeRows.Names[0] = "col1"
	//fakeRows.Names[1] = "col2"
	//fakeRows.Values[0][0] = "col1_row1"
	//fakeRows.Values[1] = "val2"
	return fakeRows, nil
}

type FakeDbRows struct {
	Names  []string
	Values []string
}

func (rows FakeDbRows) Close() error {
	return nil
}

func (rows FakeDbRows) Scan(dest ...interface{}) error {
	//for i, val := range rows.Values {
	//	dest[i] = rows.Values[0]
	//
	//}
	return nil
}

func (rows FakeDbRows) Columns() ([]string, error) {
	return rows.Names, nil
}

func (rows FakeDbRows) Next() bool {
	return false
}
