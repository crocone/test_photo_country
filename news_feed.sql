-- Создаем таблицк пользователей
CREATE TABLE `user` (
  `id` INTEGER NOT NULL AUTO_INCREMENT,
  `login` VARCHAR(32) NOT NULL,
  CONSTRAINT `user_pk` PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARACTER SET = 'UTF8';

-- Создаем таблицу категорий
CREATE TABLE `categories` (
  `id` SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `title` VARCHAR(32) NOT NULL,
  CONSTRAINT `categories_pk` PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARACTER SET = 'UTF8';

-- Создаем таблицу новостей
CREATE TABLE `news` (
  `id` INTEGER UNSIGNED  NOT NULL AUTO_INCREMENT,
  `title`  VARCHAR(32) NOT NULL,
  `description` VARCHAR(245) NOT NULL,
  `likes` INTEGER UNSIGNED  NOT NULL DEFAULT 0,
  `category_id` SMALLINT UNSIGNED NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT `news_pk` PRIMARY KEY (`id`),
  CONSTRAINT `news_fk_category_id` FOREIGN KEY (`category_id`)
    REFERENCES `categories` (`id`) ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE = InnoDB DEFAULT CHARACTER SET = 'UTF8';

-- Создаем таблицу лайков
CREATE TABLE `news_likes` (
  `news_id` INTEGER UNSIGNED  NOT NULL,
  `user_id` INTEGER NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `news_likes_pk` PRIMARY KEY (`post_id`, `user_id`),
  CONSTRAINT `news_likes_fk_news_id` FOREIGN KEY (`news_id`) REFERENCES `news` (`id`) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT `news_likes_fk_user_id` FOREIGN KEY (`user_id`)
    REFERENCES `users` (`id`) ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE = InnoDB DEFAULT CHARACTER SET = 'UTF8';

-- создаем индексы
CREATE INDEX `news_likes_created_at` ON `news_likes` (`created_at`);
CREATE INDEX `news_likes_user_id` ON `news_likes` (`user_id`);

-- добавляем триггеры для обновления кол-ва лайков, при добавлении и удалении лайка у поста
DELIMITER //
-- добавляет кол-во лайков на 1.
CREATE TRIGGER `tr_plus_news_likes` AFTER INSERT ON `news_likes` FOR EACH ROW
  UPDATE `news` SET `likes` = `likes` + 1 WHERE `id` = NEW.`news_id`;

-- уменьшает кол-во лайков на 1.
CREATE TRIGGER `tr_minus_news_likes` AFTER DELETE ON `news_likes` FOR EACH ROW
  UPDATE `news` SET `likes` = `likes` - 1 WHERE `id` = OLD.`news_id`;

//

-- добавление пользователя
INSERT INTO `user` (`login`) VALUES
  (:userLogin);

-- добавление новости
INSERT INTO `news` (`title`, `description`, `category_id`) VALUES
  (:newsTitle, :newsDescription, :newsCatId);

-- если пользователь поставил лайк
INSERT INTO `news_likes` (`news_id`, `user_id`) VALUES
  (:newsId, :userId);

-- если пользователь отменил лайк
DELETE FROM `news_likes` WHERE `news_id` = :newsId AND `user_id` = :userId;

-- получаем список новостей для отображения
SELECT
  news.*,
  cat.title
FROM
  `news`
  INNER JOIN `categories` cat ON news.`category_id` = cat.`id`
  -- если нужна выборка с учетом нужной категори
  -- добавляем
  -- WHERE `category_id` = :categoryId
ORDER BY
  news.`id` DESC
LIMIT :offset, :limit;

-- получаем список пользователей, которые лайкнули пост
SELECT
  user.*
  likes.`created_at`
FROM
  `news_likes` likes
  INNER JOIN `user` ON likes.`user_id` = user.`id`
WHERE
  likes.`news_id` = :newsId
ORDER BY
  likes.`created_at` DESC
LIMIT :offset, :limit;

-- транзакция для удаления новости
BEGIN WORK;
DELETE FROM `news` WHERE `id` = :newsId;
DELETE FROM `news_likes` WHERE `news_id` = :newsId;
COMMIT;
