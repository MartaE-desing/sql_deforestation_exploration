CREATE TABLE users (
user_id SERIAL PRIMARY KEY,
user_name VARCHAR (25) CONSTRAINT user_name_required UNIQUE NOT NULL
    CONSTRAINT user_name_not_empty CHECK(LENGTH(TRIM("user_name")) > 0),
last_login TIMESTAMP
);
CREATE INDEX login_index ON users (last_login);
CREATE INDEX find_user_by_user_name ON users (user_name);

CREATE TABLE topics (
    topic_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users ON DELETE SET NULL,
    topic_name VARCHAR (30) CONSTRAINT topic_name_required UNIQUE NOT NULL
        CONSTRAINT topic_name_not_empty CHECK(LENGTH(TRIM("topic_name")) > 0),
    topic_description VARCHAR (500)
);
CREATE INDEX find_topic_name ON topics (topic_name);

CREATE TABLE posts (
    post_id SERIAL PRIMARY KEY,
    title VARCHAR (100) NOT NULL
        CONSTRAINT title_not_empty CHECK(LENGTH(TRIM("title")) > 0),
    url TEXT,
    post_content TEXT,
    topic_id INTEGER REFERENCES topics ON DELETE CASCADE CONSTRAINT topic_required NOT NULL,
    user_id INTEGER REFERENCES users ON DELETE SET NULL,
    time_stamp_post TIMESTAMP WITH TIME ZONE,
    CONSTRAINT url_or_post_content 
    CHECK (url IS NOT NULL AND post_content IS NULL OR
          url IS NULL AND post_content IS NOT NULL)
);
CREATE INDEX latest_posts_topic ON posts (topic_id,time_stamp_post);
CREATE INDEX latest_posts_user ON posts (topic_id,user_id);
CREATE INDEX post_url ON posts (url);

CREATE TABLE comments (
    id SERIAL PRIMARY KEY,
    text_content TEXT CONSTRAINT text_content_required NOT NULL
        CONSTRAINT text_content_not_empty CHECK(LENGTH(TRIM("text_content")) > 0),
    parent_id INTEGER REFERENCES comments ON DELETE CASCADE CONSTRAINT parent_required NOT NULL,
    post_id INTEGER REFERENCES posts ON DELETE CASCADE CONSTRAINT post_required NOT NULL,
    user_id INTEGER REFERENCES users ON DELETE SET NULL, 
    time_stamp_comment TIMESTAMP WITH TIME ZONE,
    top_level INTEGER REFERENCES comments ON DELETE CASCADE CONSTRAINT top_level_required NOT NULL  
);

CREATE INDEX top_level_index ON comments (top_level);
CREATE INDEX parent_id ON comments (post_id);
CREATE INDEX comments_by_user ON comments (user_id,time_stamp_comment);

CREATE TABLE votes (
    user_id INTEGER REFERENCES users ON DELETE SET NULL,
    post_id INTEGER REFERENCES posts ON DELETE CASCADE CONSTRAINT post_required NOT NULL,
    PRIMARY KEY(user_id, post_id),
    vote INTEGER CONSTRAINT up_down CHECK(vote=1 OR vote=-1)  
);
CREATE INDEX post_score ON votes (vote);

INSERT INTO users (user_name) 
    SELECT bp.username
        FROM bad_posts AS bp
    UNION
    SELECT bc.username
        FROM bad_comments AS bc;

INSERT INTO topics (topic_name, user_id)
    SELECT bp.topic, u.user_id
        FROM bad_posts AS bp
        JOIN users AS u
            ON u.user_name = bp.username
        GROUP BY u.user_id, bp.topic;       

INSERT INTO posts (title, url, post_content, topic_id, user_id)
    SELECT LEFT(bp.title, 100), bp.url, bp.text_content, t.topic_id, u.user_id
        FROM bad_posts AS bp
    JOIN topics AS t
        ON bp.topic = t.topic_name
    JOIN users AS u
        ON bp.username = u.user_name;  

 INSERT INTO comments(text_content, post_id, user_id)
    SELECT bc.text_content, p.post_id, u.user_id
        FROM bad_comments AS bc
    JOIN bad_posts AS bp 
        ON bc.post_id = bp.id
    JOIN posts AS p 
        ON p.title = bp.title
    JOIN users AS u 
        ON bc.username = u.user_name;
