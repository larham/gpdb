from threading import Thread


class ExecThread(Thread):
    def __init__(self, cfg, db, qry):
        self.cfg = cfg
        self.db = db
        self.qry = qry
        self.curs = None
        self.error = None
        Thread.__init__(self)

    def run(self):
        try:
            self.curs = self.db.query(self.qry)
        except BaseException, e:
            self.error = e
