library(plyr)
library(rjson)
library(RCurl)
library(tidytext)
library(readr)
library(data.table)
library(ggplot2)
library(stringr)
library(dplyr)
library(gridExtra)
library(ggthemes)
library(ggalluvial)
library(reshape2)
library(lubridate)
library(tibble)
library(RColorBrewer)
library(lattice)

Sys.setlocale("LC_TIME", "English") # 讓圖表渲染時，時間會是顯示英文
options(scipen = 999) #數字不用科學記號表達

ga_df <- read_csv("C:/Users/Pacific/Desktop/Pacific/PopDaily/編輯部好文標準/All Traffic 20190701-20190910-1.csv")
editor_list_df <- read_csv("C:/Users/Pacific/Desktop/Pacific/PopDaily/編輯部好文標準/Editor_list.csv")
bq_df <- read_csv("C:/Users/Pacific/Desktop/Pacific/PopDaily/編輯部好文標準/bq-results 20190701-20190910-1.csv")
fb_fans_df <- read_csv("C:/Users/Pacific/Desktop/Pacific/PopDaily/編輯部好文標準/fb_fans.csv")

# fb_fans 資料整理
fans_df <- fb_fans_df %>%
  dplyr::select(Name, Fans)

fans_df$en_name <- sapply(fans_df$Name, function(x) strsplit(x, split = " ")[[1]][1])
fans_df$ch_name <- sapply(fans_df$Name, function(x) strsplit(x, split = " ")[[1]][2])
fans_df<- fans_df[, -3]

# 更正 ga 欄位名稱
names(ga_df) <- tolower(names(ga_df))
names(ga_df) <- str_replace(names(ga_df), "[:punct:]|[:space:]", replacement = "_")
names(editor_list_df) <- c("alias", "mid", "real_name")

# 將 GA 中的欄位 landing_page 修正為 post_id 格式
ga_df$landing_page <- gsub("^\\/", replacement = "", ga_df$landing_page)
ga_df$landing_page <- gsub("\\/", replacement = ".", ga_df$landing_page)
ga_df$post_id <- gsub("\\?sfrom=[A-z0-9]*", replacement = "", ga_df$landing_page)
ga_df <- ga_df[, -2]

# join 表格
popdaily <- dplyr::inner_join(ga_df, bq_df, by = "post_id")
popdaily <- dplyr::inner_join(popdaily ,editor_list_df, by = "mid")
popdaily_df <- popdaily %>% 
  dplyr::select(post_id, source_medium, post_date, mid, alias, real_name, count_view, sessions)

# 將 ga 不同的 affliate 分組統計 sessions
source_df <- ga_df %>% 
  dplyr::group_by(source_medium) %>%
  dplyr::summarise(sum_user = sum(sessions)) %>%
  dplyr::filter(sum_user != 0) %>%
  dplyr::arrange(desc(sum_user))

popdaily_df <- dplyr::inner_join(popdaily_df, source_df, by = "source_medium")

# 將 source_medium 分為 fb、ig、direct 和 other 並設成新變數 social_media
popdaily_df <- popdaily_df %>%
  dplyr::mutate(social_media = ifelse(str_detect(popdaily_df$source_medium, "facebook"), "facebook",
                                      ifelse(str_detect(popdaily_df$source_medium, "instagram"), "instagram", 
                                             ifelse(str_detect(popdaily_df$source_medium, "direct"), "direct", "other"))))

# 將不同 social_media 計算 sessions 的平均數
popdaily_user_by_social <- popdaily_df %>%
  dplyr::group_by(social_media) %>%
  dplyr::summarise(user_by_social = round(mean(sessions))) 

popdaily_df <- dplyr::inner_join(popdaily_df, popdaily_user_by_social, by = "social_media")

# 將不同 social_media 能導流的能力做比例運算，產生新變數 social_score 和 view_score
popdaily_df <- popdaily_df %>%
  dplyr::mutate(social_score = ifelse(str_detect(popdaily_df$source_medium, "facebook"), (popdaily_user_by_social$user_by_social[popdaily_user_by_social$social_media == "facebook"])/(sum(popdaily_user_by_social$user_by_social)),
                                      ifelse(str_detect(popdaily_df$source_medium, "instagram"), (popdaily_user_by_social$user_by_social[popdaily_user_by_social$social_media == "instagram"])/(sum(popdaily_user_by_social$user_by_social)),
                                             ifelse(str_detect(popdaily_df$source_medium, "direct"), (popdaily_user_by_social$user_by_social[popdaily_user_by_social$social_media == "direct"])/(sum(popdaily_user_by_social$user_by_social)), (popdaily_user_by_social$user_by_social[popdaily_user_by_social$social_media == "other"])/(sum(popdaily_user_by_social$user_by_social))))), 
                view_score = round(count_view*(1/social_score)))

# 計算每篇文章的 view_score_score
post_view_score <- popdaily_df %>%
  dplyr::group_by(post_id) %>%
  dplyr::summarise(post_view_score = round(mean(view_score)))

popdaily_df <- dplyr::inner_join(popdaily_df, post_view_score, by = "post_id")
  
# 計算每篇文章被推廣過的次數
n_source <- popdaily_df %>% 
  dplyr::group_by(post_id) %>%
  dplyr::summarise(n_source = n())

popdaily_df <- dplyr::inner_join(popdaily_df, n_source, by = "post_id")

# 再將來源分為 socialmedia、ig 和其他
popdaily_df <- popdaily_df %>%
  dplyr::mutate(affliate = ifelse(str_detect(popdaily_df$social_media, "facebook"), "socialmedia",
                                  ifelse(str_detect(popdaily_df$social_media, "instagram"), "socialmedia", "others")))

ggplot(popdaily_df, aes(x = real_name, y = sessions, fill = social_media)) +
  geom_bar(stat = "identity", position = "fill") +
  coord_flip() +
  labs(y = "Proportion of sessions", 
       x = "Author", 
       title = "Outcomes:social media affliate ") +
  scale_fill_brewer(palette = "PuOr") +
  theme_fivethirtyeight()

# 依照 post_id 將需要的變數取出
popdaily_fin <- popdaily_df %>% 
  dplyr::select(post_id, post_date, mid, real_name, 
                count_view, post_view_score, n_source) %>%
  dplyr::arrange(desc(post_id))

popdaily_fin <- popdaily_fin %>%
  dplyr::group_by(post_id) %>%
  unique() %>%
  dplyr::arrange(desc(post_id))

# 計算每個作者的平均 post_view_score
real_name_mean_view <- popdaily_fin %>% 
  dplyr::group_by(real_name) %>%
  dplyr::summarise(real_name_mean_view = round(mean(post_view_score)))

# 計算每個作者 mid 的平均 post_view_score
mid_mean_view <- popdaily_fin %>% 
  dplyr::group_by(mid) %>%
  dplyr::summarise(mid_mean_view = round(mean(post_view_score)))

popdaily_fin <- dplyr::inner_join(popdaily_fin, real_name_mean_view, by = "real_name")
popdaily_fin <- dplyr::inner_join(popdaily_fin, mid_mean_view, by = "mid")

# 計算 mid 整體平均 post_view_score
mid_mean <- popdaily_fin %>% 
  dplyr::group_by(real_name, mid) %>%
  dplyr::summarise(view = mean(mid_mean_view))

mid_mean$mid <- as.character(mid_mean$mid)

ggplot(mid_mean, aes(x = view, y = mid)) +
  geom_segment(aes(yend = mid), xend = 0, color = "grey50") +
  geom_point(size = 2, color = "red", alpha = 0.5) +
  geom_text(aes(label = view),hjust = 0.9, vjust = -0.3) +
  geom_vline(data = plyr::ddply(mid_mean, "real_name", summarize, mean_view = mean(view)), aes(xintercept = mean_view, color = real_name)) +
  scale_x_log10() +
  facet_wrap(~ real_name, nrow = 1) +
  labs(y = "amount of views", 
       x = "mid", 
       title = "Outcomes:view of mid ") +
  scale_fill_brewer(palette = "PuOr") +
  theme(panel.grid.major.y = element_blank()) +
  theme_fivethirtyeight()

# 將每篇文的分數除以來源數，得到新變數 score，mid 平均 view 應該要從 gcp 裡撈取過去所有資料
popdaily_fin <- popdaily_fin %>%
  dplyr::mutate(score = ((post_view_score - mid_mean_view)/n_source)) %>%
  dplyr::arrange(desc(score))

ggplot(popdaily_fin, aes(x = real_name, y = score)) + 
  geom_boxplot() +
  stat_summary(fun.y = mean, geom = "point", shape = 7, size = 3, color = "orange", alpha = 0.6) +
  theme_fivethirtyeight()

# 計算每個人的標準差，產生新變數 sd_score
name_sd <- plyr::ddply(popdaily_fin, "real_name", summarize, sd_score = sd(score))

popdaily_fin <- dplyr::inner_join(popdaily_fin, name_sd, by = "real_name")

name_mean <- plyr::ddply(popdaily_fin, "real_name", summarize, mean_score = round(mean(score)))

popdaily_fin <- dplyr::inner_join(popdaily_fin, name_mean, by = "real_name")

popdaily_fin$n_sd <- (popdaily_fin$score - popdaily_fin$mean_score)/(popdaily_fin$sd_score)

# 利用常態分配概略算出機率密度
standard <- function(x) x*0.5*0.674
standard_2 <- function(y) y*0.341*0.445 + y*0.136*1.335 + y*0.021*2.255 + y*0.001*3.2 

k <- standard_2((nrow(popdaily_fin)/length(unique(popdaily_fin$real_name)))) - standard((nrow(popdaily_fin)/length(unique(popdaily_fin$real_name))))

n_name_df <- plyr::ddply(popdaily_fin, "real_name", dplyr::summarize, n = n())

popdaily_bonus_df <- popdaily_fin %>%
  dplyr::filter(n_sd >= 0 & post_view_score > quantile(popdaily_fin$post_view_score, 0.33)) %>%
  dplyr::group_by(real_name) %>%
  dplyr::summarise(sum_sd = sum(n_sd)) %>%
  dplyr::inner_join(n_name_df, by = "real_name") %>%
  dplyr::mutate(standard = standard(n)) %>%
  dplyr::mutate(standard_2 = standard_2(n))
  
popdaily_bonus_df <- popdaily_bonus_df %>%
  dplyr::mutate(bonus = ifelse(popdaily_bonus_df$sum_sd < popdaily_bonus_df$standard, 0, 
                               ifelse(popdaily_bonus_df$sum_sd >= popdaily_bonus_df$standard & popdaily_bonus_df$sum_sd < popdaily_bonus_df$standard_2, 1000, 2000)))

popdaily_fin %>%
  ggplot(aes(x = score)) + 
  geom_density(aes(color = real_name)) +
  geom_vline(data = plyr::ddply(popdaily_fin, "real_name", summarize, mean_score = mean(score)), aes(xintercept = mean_score, color = real_name)) +
  facet_wrap(~ real_name, nrow = 3) +
  theme_fivethirtyeight()

