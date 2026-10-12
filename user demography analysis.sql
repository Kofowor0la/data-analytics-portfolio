SELECT * FROM practice_db.user;
USE practice_db;

SELECT * 
FROM `user`
LIMIT 10;
USE practice_db;

SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT email) AS unique_emails,
    COUNT(DISTINCT name) AS unique_names,
    COUNT(DISTINCT location) AS unique_locations,
    COUNT(DISTINCT gender) AS gender_categories,
    COUNT(DISTINCT language_spoken) AS languages_represented,
    SUM(CASE WHEN email IS NULL OR TRIM(email) = ''
             THEN 1 ELSE 0 END) AS missing_emails,
    SUM(CASE WHEN date_of_birth IS NULL
             THEN 1 ELSE 0 END) AS missing_birth_dates,
    SUM(CASE WHEN location IS NULL OR TRIM(location) = ''
             THEN 1 ELSE 0 END) AS missing_locations
FROM `user`;

SELECT
    COUNT(*) AS total_records,

    SUM(
        CASE
            WHEN name IS NULL OR TRIM(name) = ''
            THEN 1 ELSE 0
        END
    ) AS missing_names,

    SUM(
        CASE
            WHEN email IS NULL OR TRIM(email) = ''
            THEN 1 ELSE 0
        END
    ) AS missing_emails,

    SUM(
        CASE
            WHEN email IS NOT NULL
                 AND TRIM(email) <> ''
                 AND email NOT LIKE '%_@_%._%'
            THEN 1 ELSE 0
        END
    ) AS suspicious_email_formats,

    SUM(
        CASE
            WHEN date_of_birth IS NULL
                 OR date_of_birth > CURDATE()
            THEN 1 ELSE 0
        END
    ) AS invalid_birth_dates,

    SUM(
        CASE
            WHEN location IS NULL OR TRIM(location) = ''
            THEN 1 ELSE 0
        END
    ) AS missing_locations,

    SUM(
        CASE
            WHEN gender IS NULL OR TRIM(gender) = ''
            THEN 1 ELSE 0
        END
    ) AS missing_gender,

    SUM(
        CASE
            WHEN language_spoken IS NULL
                 OR TRIM(language_spoken) = ''
            THEN 1 ELSE 0
        END
    ) AS missing_languages

FROM `user`;

SELECT
    COALESCE(NULLIF(TRIM(gender), ''), 'Unknown') AS gender_category,

    COUNT(*) AS total_users,

    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM `user`),
        2
    ) AS percentage_of_users

FROM `user`

GROUP BY COALESCE(NULLIF(TRIM(gender), ''), 'Unknown')

ORDER BY total_users DESC;

SELECT
    TRIM(SUBSTRING_INDEX(location, ',', -1)) AS country,

    COUNT(*) AS total_users,

    COUNT(DISTINCT language_spoken) AS different_languages,

    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM `user`),
        2
    ) AS percentage_of_all_records

FROM `user`

WHERE location IS NOT NULL
  AND TRIM(location) <> ''

GROUP BY TRIM(SUBSTRING_INDEX(location, ',', -1))

ORDER BY total_users DESC;

SELECT
    COALESCE(
        NULLIF(TRIM(language_spoken), ''),
        'Unknown'
    ) AS language,

    COUNT(*) AS total_users,

    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM `user`),
        2
    ) AS percentage_of_users

FROM `user`

GROUP BY COALESCE(
    NULLIF(TRIM(language_spoken), ''),
    'Unknown'
)

ORDER BY total_users DESC;

SELECT
    age_group,
    COUNT(*) AS total_users,

    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_of_users

FROM (
    SELECT
        CASE
            WHEN date_of_birth IS NULL
                 OR date_of_birth > CURDATE()
            THEN 'Unknown'

            WHEN TIMESTAMPDIFF(
                YEAR,
                date_of_birth,
                CURDATE()
            ) < 18
            THEN 'Under 18'

            WHEN TIMESTAMPDIFF(
                YEAR,
                date_of_birth,
                CURDATE()
            ) BETWEEN 18 AND 24
            THEN '18-24'

            WHEN TIMESTAMPDIFF(
                YEAR,
                date_of_birth,
                CURDATE()
            ) BETWEEN 25 AND 34
            THEN '25-34'

            WHEN TIMESTAMPDIFF(
                YEAR,
                date_of_birth,
                CURDATE()
            ) BETWEEN 35 AND 44
            THEN '35-44'

            WHEN TIMESTAMPDIFF(
                YEAR,
                date_of_birth,
                CURDATE()
            ) BETWEEN 45 AND 54
            THEN '45-54'

            ELSE '55+'
        END AS age_group

    FROM `user`
) AS age_analysis

GROUP BY age_group

ORDER BY
    CASE age_group
        WHEN 'Under 18' THEN 1
        WHEN '18-24' THEN 2
        WHEN '25-34' THEN 3
        WHEN '35-44' THEN 4
        WHEN '45-54' THEN 5
        WHEN '55+' THEN 6
        ELSE 7
    END;
    
    SELECT
    TRIM(SUBSTRING_INDEX(location, ',', -1)) AS country,

    COUNT(*) AS total_users,

    ROUND(
        AVG(
            TIMESTAMPDIFF(
                YEAR,
                date_of_birth,
                CURDATE()
            )
        ),
        1
    ) AS average_age,

    MIN(
        TIMESTAMPDIFF(
            YEAR,
            date_of_birth,
            CURDATE()
        )
    ) AS youngest_age,

    MAX(
        TIMESTAMPDIFF(
            YEAR,
            date_of_birth,
            CURDATE()
        )
    ) AS oldest_age

FROM `user`

WHERE location IS NOT NULL
  AND TRIM(location) <> ''
  AND date_of_birth IS NOT NULL
  AND date_of_birth <= CURDATE()

GROUP BY TRIM(SUBSTRING_INDEX(location, ',', -1))

ORDER BY average_age DESC;

SELECT
    LOWER(TRIM(email)) AS normalized_email,

    COUNT(*) AS occurrences

FROM `user`

WHERE email IS NOT NULL
  AND TRIM(email) <> ''

GROUP BY LOWER(TRIM(email))

HAVING COUNT(*) > 1

ORDER BY occurrences DESC;

WITH language_summary AS (
    SELECT
        TRIM(SUBSTRING_INDEX(location, ',', -1)) AS country,

        COALESCE(
            NULLIF(TRIM(language_spoken), ''),
            'Unknown'
        ) AS language,

        COUNT(*) AS total_users

    FROM `user`

    WHERE location IS NOT NULL
      AND TRIM(location) <> ''

    GROUP BY
        TRIM(SUBSTRING_INDEX(location, ',', -1)),
        COALESCE(
            NULLIF(TRIM(language_spoken), ''),
            'Unknown'
        )
),

ranked_languages AS (
    SELECT
        country,
        language,
        total_users,

        DENSE_RANK() OVER (
            PARTITION BY country
            ORDER BY total_users DESC
        ) AS language_rank

    FROM language_summary
)

SELECT
    country,
    language,
    total_users,
    language_rank

FROM ranked_languages

WHERE language_rank <= 3

ORDER BY country, language_rank, language;

SELECT
    COUNT(*) AS total_users,

    COUNT(DISTINCT email) AS distinct_emails,

    COUNT(DISTINCT location) AS distinct_locations,

    COUNT(DISTINCT language_spoken) AS distinct_languages,

    ROUND(
        AVG(
            CASE
                WHEN date_of_birth <= CURDATE()
                THEN TIMESTAMPDIFF(
                    YEAR,
                    date_of_birth,
                    CURDATE()
                )
            END
        ),
        1
    ) AS average_age,

    SUM(
        CASE
            WHEN gender = 'Male'
            THEN 1 ELSE 0
        END
    ) AS male_records,

    SUM(
        CASE
            WHEN gender = 'Female'
            THEN 1 ELSE 0
        END
    ) AS female_records,

    SUM(
        CASE
            WHEN email IS NULL OR TRIM(email) = ''
            THEN 1 ELSE 0
        END
    ) AS missing_email_records

FROM `user`;



    
    