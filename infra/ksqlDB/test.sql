-- CREATING BASIC PRODUCTS STREAM


-- POSTMETA TABLE

DROP TABLE IF EXISTS POSTMETA_TABLE;
CREATE TABLE POSTMETA_TABLE
(KEY VARCHAR PRIMARY KEY)
WITH (KAFKA_TOPIC='mysql-server.wordpress.wp_postmeta', VALUE_FORMAT='AVRO');

DROP TABLE IF EXISTS POSTMETA_TABLE_GROUPBY_POSTID;
CREATE TABLE POSTMETA_TABLE_GROUPBY_POSTID
AS SELECT 
  POST_ID,
  COLLECT_LIST(
    STRUCT(
        KEY := META_KEY
      , VALUE := META_VALUE
    )
  ) AS METADATA
FROM POSTMETA_TABLE
WHERE META_KEY IN (
    '_regular_price'
  , '_sale_price'
  , '_price'
)
GROUP BY POST_ID
EMIT CHANGES;



-- POSTS TABLE

DROP STREAM IF EXISTS POSTS_STREAM;
CREATE STREAM POSTS_STREAM
WITH (KAFKA_TOPIC='mysql-server.wordpress.wp_posts', VALUE_FORMAT='AVRO');

-- DROP TABLE IF EXISTS POSTS_TABLE;
-- CREATE TABLE POSTS_TABLE AS
-- SELECT 
--     ID
--   , LATEST_BY_OFFSET(POST_DATE) AS DATE
--   , LATEST_BY_OFFSET(POST_TITLE) AS TITLE
--   , LATEST_BY_OFFSET(POST_CONTENT) AS CONTENT
--   , LATEST_BY_OFFSET(POST_STATUS) AS STATUS
--   , LATEST_BY_OFFSET(POST_NAME) AS NAME
--   , LATEST_BY_OFFSET(POST_TYPE) AS TYPE
-- FROM POSTS_STREAM
-- GROUP BY ID;

-- DROP TABLE IF EXISTS PRODUCTS;
-- CREATE TABLE PRODUCTS AS
-- SELECT 
--     P.ID
--   , P.DATE
--   , P.TITLE
--   , P.CONTENT
--   , P.STATUS
--   , P.NAME
--   , P.TYPE
--   , PM.METADATA
-- FROM POSTS_TABLE P
-- LEFT JOIN POSTMETA_TABLE_GROUPBY_POSTID PM
-- ON P.ID = PM.POST_ID
-- WHERE P.STATUS = 'publish' AND P.TYPE = 'product'
-- EMIT CHANGES;

DROP TABLE IF EXISTS POSTS_TABLE;
CREATE TABLE POSTS_TABLE
(KEY VARCHAR PRIMARY KEY)
WITH (KAFKA_TOPIC='mysql-server.wordpress.wp_posts', VALUE_FORMAT='AVRO');



-- PRODUCTS TABLE

DROP TABLE IF EXISTS PRODUCTS_TABLE;
CREATE TABLE PRODUCTS_TABLE AS
SELECT 
    P.KEY
  , P.ID
  , P.POST_DATE AS DATE
  , P.POST_TITLE AS TITLE
  , P.POST_CONTENT AS CONTENT
  , P.POST_STATUS AS STATUS
  , P.POST_NAME AS NAME
  , P.POST_TYPE AS TYPE
  , PM.METADATA
FROM POSTS_TABLE P
LEFT JOIN POSTMETA_TABLE_GROUPBY_POSTID PM
ON P.ID = PM.POST_ID
WHERE P.post_status = 'publish' AND P.post_type = 'product'
EMIT CHANGES;


DROP STREAM IF EXISTS PRODUCTS;
CREATE STREAM PRODUCTS
WITH (KAFKA_TOPIC='PRODUCTS_TABLE', VALUE_FORMAT='AVRO');






-- TERMMETA TABLE

DROP TABLE IF EXISTS TERMMETA_TABLE;
CREATE TABLE TERMMETA_TABLE
(KEY VARCHAR PRIMARY KEY)
WITH (KAFKA_TOPIC='mysql-server.wordpress.wp_termmeta', VALUE_FORMAT='AVRO');

DROP TABLE IF EXISTS TERMMETA_TABLE_GROUPBY_TERMID;
CREATE TABLE TERMMETA_TABLE_GROUPBY_TERMID
AS SELECT 
  TERM_ID,
  COLLECT_LIST(
    STRUCT(
        KEY := META_KEY
      , VALUE := META_VALUE
    )
  ) AS METADATA
FROM TERMMETA_TABLE
GROUP BY TERM_ID
EMIT CHANGES;


-- TERMS TABLE

DROP TABLE IF EXISTS TERMS_TABLE;
CREATE TABLE TERMS_TABLE
(KEY VARCHAR PRIMARY KEY)
WITH (KAFKA_TOPIC='mysql-server.wordpress.wp_terms', VALUE_FORMAT='AVRO');

DROP TABLE IF EXISTS TERMS_ENRICHED_TABLE;
CREATE TABLE TERMS_ENRICHED_TABLE AS
SELECT 
    T.KEY
  , T.TERM_ID
  , T.NAME
  , T.SLUG
  , T.TERM_GROUP
  , TM.METADATA
FROM TERMS_TABLE T
LEFT JOIN TERMMETA_TABLE_GROUPBY_TERMID TM
ON T.TERM_ID = TM.TERM_ID
EMIT CHANGES;


-- TERM_TAXONOMY TABLE

DROP TABLE IF EXISTS TERM_TAXONOMY_TABLE;
CREATE TABLE TERM_TAXONOMY_TABLE
(KEY VARCHAR PRIMARY KEY)
WITH (KAFKA_TOPIC='mysql-server.wordpress.wp_term_taxonomy', VALUE_FORMAT='AVRO');

DROP TABLE IF EXISTS TERM_TAXONOMY_ENRICHED_TABLE;
CREATE TABLE TERM_TAXONOMY_ENRICHED_TABLE AS
SELECT 
    T.KEY
  , T.TERM_ID
  , T.NAME
  , T.SLUG
  , T.TERM_GROUP
  , TM.METADATA
FROM TERMS_TABLE T
LEFT JOIN TERMMETA_TABLE_GROUPBY_TERMID TM
ON T.TERM_ID = TM.TERM_ID
EMIT CHANGES;




-- TESTING 

-- DROP STREAM IF EXISTS test_array;
-- CREATE STREAM test_array (
--   POST_ID VARCHAR,
--   METADATA ARRAY<STRUCT<META_KEY VARCHAR(STRING), META_VALUE VARCHAR(STRING)>>
-- ) WITH (
--   kafka_topic = 'POSTMETA_TABLE_GROUPBY_POSTID',
--   value_format = 'avro'
-- );

DROP TABLE IF EXISTS test_array_outttt;
CREATE TABLE test_array_outttt AS
  SELECT POST_ID, 
  TRANSFORM(METADATA, x => TRANSFORM(x, (k, v) => UCASE(k), (k, v) => v)) AS META
  FROM POSTMETA_TABLE_GROUPBY_POSTIDDD;




DROP STREAM IF EXISTS PRODUCTS;
DROP TABLE IF EXISTS PRODUCTS_TABLE;
DROP TABLE IF EXISTS POSTS_TABLE;


DROP STREAM IF EXISTS POSTS_STREAM;
CREATE STREAM POSTS_STREAM
WITH (KAFKA_TOPIC='mysql-server.wordpress.wp_posts', VALUE_FORMAT='AVRO');



SELECT P.ID AS ID,
       STRUCT(META_ID := PM.META_ID,
              META_KEY := PM.META_KEY
              META_VALUE := PM.META_VALUE) AS POSTMETA_STREAM
FROM POSTS_STREAM P 
LEFT JOIN POSTMETA_STREAM_BY_POSTID PM
WITHIN 365 DAYS
ON P.ID = PM.POST_ID
EMIT CHANGES;

SELECT PS.PRODUCT_ID AS PRODUCT_ID,
      STRUCT(NAME        := PS.NAME,
              STOCK       := PS.STOCK,
              PRICE       := PS.PRICE,
              STORAGE_IDS := PS.STORAGE_IDS) AS PRODUCT_SUPPLY,
      STRUCT(DESCRIPTION  := PI.DESCRIPTION,
              MANUFACTURER := PI.MANUFACTURER,
              VENDOR_ID    := PI.VENDOR_ID) AS PRODUCT_INFORMATION
  FROM PRODUCT_SUPPLY PS
      LEFT JOIN PRODUCT_INFORMATION PI
      ON PS.PRODUCT_ID=PI.PRODUCT_ID
EMIT CHANGES LIMIT 1;



DROP TABLE IF EXISTS POSTS_TABLE; \
CREATE TABLE POSTS_TABLE \
(ID VARCHAR PRIMARY KEY) \
WITH (KAFKA_TOPIC='mysql-server.wordpress.wp_posts', VALUE_FORMAT='AVRO');

DROP TABLE IF EXISTS POSTMETA_TABLE; \
CREATE TABLE POSTMETA_TABLE \
(KEY VARCHAR PRIMARY KEY) \
WITH (KAFKA_TOPIC='mysql-server.wordpress.wp_postmeta', VALUE_FORMAT='AVRO');


CREATE TABLE PRODUCTS_TABLE AS 
SELECT pm.*, p.* 
FROM POSTS_TABLE p 
LEFT JOIN POSTMETA_TABLE pm ON p.ID = pm.POST_ID;


CREATE STREAM PRODUCTS AS
SELECT pm.*, p.*
FROM POSTS_TABLE p
LEFT JOIN POSTMETA_TABLE pm
ON p.ID = pm.POST_ID;





SET 'auto.offset.reset' = 'earliest';

SELECT * FROM POSTS_META_TABLE EMIT CHANGES;

SELECT * FROM POSTS_META_STREAM EMIT CHANGES;


CREATE TABLE POSTS_META_STREAM_BY_POSTID AS SELECT * FROM POSTS_META_TABLE WHERE POST_ID IS NOT NULL;


CREATE STREAM PRODUCTS AS
SELECT pmt.*, pt.*
FROM POSTS_TABLE pt
LEFT JOIN POSTS_META_STREAM_BY_POSTID pmt
ON pt.ID = pmt.POST_ID;


DROP TABLE IF EXISTS POSTS_META_TABLE;

CREATE TABLE POSTS_META_TABLE AS \
SELECT meta_id, LATEST_BY_OFFSET(post_id) AS post_id, 
       LATEST_BY_OFFSET(meta_key) AS meta_key, 
       LATEST_BY_OFFSET(meta_value) AS meta_value 
FROM POSTS_META_STREAM 
GROUP BY meta_id;


DROP TABLE IF EXISTS POSTS_META_TABLE;
CREATE TABLE POSTS_META_TABLE 
(meta_id INT PRIMARY KEY, post_id INT, meta_key VARCHAR, meta_value VARCHAR) 
WITH (KAFKA_TOPIC='mysql-server.wordpress.wp_postmeta', VALUE_FORMAT='JSON');