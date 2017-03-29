package backup

import (
	"backup_restore/db"
	"backup_restore/utils"
	"fmt"
	"os"
)

var connection *db.DBConn

func SetUp() *db.DBConn {
	connection = db.NewDBConn("", "", 0, "localhost")
	err := connection.Connect()
	//fmt.Printf("got err: %v\n", err)
	utils.CheckError(err)
	fmt.Println("Got through setup")
	return connection
}

func DoBackup(connection *db.DBConn) {
	fmt.Println("The current time is", utils.CurrentTimestamp())
	rows, err := connection.GetRows("select schemaname,tablename from pg_tables")
	utils.CheckError(err)
	for _, datum := range rows {
		fmt.Printf("The schema for table %s is %s\n", datum[1], datum[0])
	}
}

func TearDown() {
	fmt.Println("Got to tearDown")
	os.Exit(0)
}
