-- @Description Tests the basic behavior of (lazy) vacuum w.r.t. to the threshold guc.
-- The output depends on the number of segments as the skip decision and the 
-- notify is done on the segments.

CREATE TABLE uaocs_threshold (a INT, b INT, c CHAR(128)) WITH (appendonly=true, orientation=column);
CREATE INDEX uaocs_threshold_index ON uaocs_threshold(b);
INSERT INTO uaocs_threshold SELECT i as a, 1 as b, 'hello world' as c FROM generate_series(1, 100) AS i;

\set QUIET off
VACUUM uaocs_threshold;
DELETE FROM uaocs_threshold WHERE a < 4;
SELECT COUNT(*) FROM uaocs_threshold;
SELECT DISTINCT segno, tupcount, state FROM gp_toolkit.__gp_aocsseg_name('uaocs_threshold');
-- 97 visible tuples, no vacuum
VACUUM uaocs_threshold;
SELECT DISTINCT segno, tupcount, state FROM gp_toolkit.__gp_aocsseg_name('uaocs_threshold');
DELETE FROM uaocs_threshold WHERE a < 12;
SELECT DISTINCT segno, tupcount, state FROM gp_toolkit.__gp_aocsseg_name('uaocs_threshold');
-- 89 visible tuples, do vacuum
VACUUM uaocs_threshold;
SELECT DISTINCT segno, tupcount, state FROM gp_toolkit.__gp_aocsseg_name('uaocs_threshold');
-- no invisible tuples, no vacuum
VACUUM uaocs_threshold;
SELECT DISTINCT segno, tupcount, state FROM gp_toolkit.__gp_aocsseg_name('uaocs_threshold');
DELETE FROM uaocs_threshold WHERE a < 15;
SELECT DISTINCT segno, tupcount, state FROM gp_toolkit.__gp_aocsseg_name('uaocs_threshold');
-- 3 invisible tuples, no vacuum
VACUUM uaocs_threshold;
SELECT DISTINCT segno, tupcount, state FROM gp_toolkit.__gp_aocsseg_name('uaocs_threshold');
SET gp_appendonly_compaction_threshold=2;
-- 3 invisible tuples, no vacuum
VACUUM uaocs_threshold;
SELECT DISTINCT segno, tupcount, state FROM gp_toolkit.__gp_aocsseg_name('uaocs_threshold');
