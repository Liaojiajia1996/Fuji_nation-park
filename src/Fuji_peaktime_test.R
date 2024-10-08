library(dplyr)
library(tidyr)
library(lubridate)
library(ggplot2)
library(ggsignif)
library(gridExtra)
library(knitr)

combined <- read.csv("/Users/liaojiajia/Downloads/富士山吉田登山口_国内居住者・来訪者属性分析_20220701_20220701/4_TimeUnit_Total_20240906120237.csv", fileEncoding = "Shift-JIS")
head(combined)

########################### Step 1: Unzip all files
# 先在终端将压缩包全都解压，才能提取目标文件，终端代码如下
# /Users/liaojiajia/博士研究/NIES/富士/富士山山口/时间：为压缩包所在文件
# cd /Users/liaojiajia/博士研究/NIES/富士/半山腰休息站/时间
# for z in *.zip; do unzip "$z" -d "${z%*.zip}"; done

## Batch filter target files and add time
# 父目录
parent_directory <- "/Users/liaojiajia/博士研究/NIES/富士/富士山山口/时间"

# 输出目录
output_directory <- "/Users/liaojiajia/博士研究/NIES/富士/富士山山口/combine"

# 确保输出目录存在
if (!dir.exists(output_directory)) {
  dir.create(output_directory, recursive = TRUE)
}

subdirectories <- list.files(path = parent_directory, full.names = TRUE, recursive = FALSE)
process_directory <- function(directory) {
  date_from_folder <- gsub(".*_(\\d{8})_\\d{8}$", "\\1", basename(directory))
  csv_files <- list.files(directory, pattern = "^4_TimeUnit_Total_.*\\.csv$", full.names = TRUE)
  lapply(csv_files, function(file) {
    data <- read.csv(file, fileEncoding = "Shift-JIS")
    data$Date <- date_from_folder
   
    output_file_path <- file.path(output_directory, paste0("modified_", basename(file)))
    
    write.csv(data, output_file_path, row.names = FALSE, fileEncoding = "Shift-JIS")
  })
}

invisible(lapply(subdirectories, process_directory))

cat("All files processed and saved to:", output_directory, "\n")

########################### Step 2: Extract daily peak hours

path <- "/Users/liaojiajia/博士研究/NIES/富士/富士山山口/combine"
files <- list.files(path, pattern = "*.csv", full.names = TRUE)
all_data <- lapply(files, function(file) {
  read.csv(file, fileEncoding = "Shift-JIS", colClasses = c("Date" = "character"))
}) %>% bind_rows()

# 确保Date列转换为标准的日期格式
all_data$Date <- as.Date(all_data$Date, format = "%Y%m%d")
all_data_long <- all_data %>%
  mutate(pop = 男性 + 女性) %>% 
  select(Date, 富士山吉田登山口, pop) %>% 
  pivot_longer(
    cols = -c("富士山吉田登山口", "Date"), 
    names_to = "Category",
    values_to = "Flow"
  )
all_data_long <- all_data_long %>%
  mutate(Time_Slot = gsub("時半", ":30", `富士山吉田登山口`),
         Time_Slot = gsub("時", ":00", Time_Slot),
         Time_Slot = format(strptime(Time_Slot, format = "%H:%M"), "%H:%M")) 

# 排除流量为0的时段，提取每个时段的最大人数
all_data_long <- all_data_long %>%
  filter(Flow > 0) %>%  # 排除流量为0的时段
  group_by(Date, `富士山吉田登山口`, Time_Slot) %>%
  summarise(Flow = max(Flow, na.rm = TRUE), .groups = "drop") 

# 确保每个日期的所有高峰时段被记录
daily_max_flow <- all_data_long %>%
  group_by(Date) %>%
  filter(Flow == max(Flow)) 
daily_max_flow$Year <- format(daily_max_flow$Date, "%Y")

# 定义一个函数用于绘制高峰时段分布图
plot_peak_visitor_times <- function(data, year) {
  # 转换为时间对象以确保时间顺序
  data$Time_Slot <- as.POSIXct(data$Time_Slot, format = "%H:%M")
 print(daily_max_flow)
  
   # 绘制指定年份7月份高峰时段的分布图
  ggplot(data, aes(x = Time_Slot)) +
    geom_bar(fill = "#e5ce81", color = "#e5ce81") +
    geom_text(stat = 'count', aes(label = ..count..), vjust = -0.3, position = position_dodge(width = 0.8)) +
    scale_x_datetime(date_labels = "%H:%M", date_breaks = "1 hour") + 
    labs(title = paste("Peak Visitor Times in July at Summit", year),
         x = "Time Slot",
         y = "Count of Peak Occurrences") +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
}

# 2022/7
july_2022_data <- daily_max_flow %>%
  filter(Year == "2022" & month(Date) == 7)
plot_peak_visitor_times(july_2022_data, "2022")

# 2023/7
july_2023_data <- daily_max_flow %>%
  filter(Year == "2023" & month(Date) == 7)
plot_peak_visitor_times(july_2023_data, "2023")

# 2024/7
july_2024_data <- daily_max_flow %>%
  filter(Year == "2024" & month(Date) == 7)
plot_peak_visitor_times(july_2024_data, "2024")


########################### Step 3: Statistical analysis
# 统计每个 Time_Slot 在每个年份的总频次
peak_data <- daily_max_flow %>%
  group_by(Time_Slot, Year) %>%
  summarise(Frequency = n(), .groups = "drop") 

peak_data_wide <- pivot_wider(peak_data, names_from = Year, values_from = Frequency, values_fill = list(Frequency = 0))
wilcox.test(peak_data_wide$`2023`, peak_data_wide$`2024`, paired = T)
wilcox.test(peak_data_wide$`2022`, peak_data_wide$`2024`, paired = T)
wilcox.test(peak_data_wide$`2022`, peak_data_wide$`2023`, paired = T)

ggplot(daily_max_flow, aes(x = Year, y = as.numeric(format(as.POSIXct(Time_Slot, format = "%H:%M"), "%H")) + 
                             as.numeric(format(as.POSIXct(Time_Slot, format = "%H:%M"), "%M")) / 60)) +
  geom_boxplot(aes(fill = Year), show.legend = FALSE) +
  geom_jitter(width = 0.1, alpha = 0.5) +
  labs(title = "Significance of Changes in Peak Visitor Times by Year",
       x = "Year",
       y = "Peak Time (Hour of the Day)") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  geom_signif(
    comparisons = list(c("2022", "2023")),
    annotations = "NS.",
    map_signif_level = FALSE,
    y_position = 22 
  ) +
  geom_signif(
    comparisons = list(c("2023", "2024")),
    annotations = "**",
    map_signif_level = FALSE,
    y_position = 23 
  ) +
  geom_signif(
    comparisons = list(c("2022", "2024")),
    annotations = "***",
    map_signif_level = FALSE,
    y_position = 24 
  )

########################### Number of visitors per day
# Batch file extraction
# 定义主文件夹路径
main_path <- "/Users/liaojiajia/博士研究/NIES/富士/富士山山口/时间" 
# 列出所有子文件夹
folders <- list.dirs(main_path, full.names = TRUE, recursive = FALSE)
# 定义一个函数来处理每个文件夹
process_folder <- function(folder) {
  # 提取文件夹名称的最后 8 位作为日期
  folder_date <- substr(basename(folder), nchar(basename(folder)) - 7, nchar(basename(folder)))
  # 列出以 "3_Summary" 开头的 CSV 文件
  summary_file <- list.files(folder, pattern = "^3_Summary.*\\.csv$", full.names = TRUE)
  # 添加日期列
  if (length(summary_file) == 1) {
    data <- read.csv(summary_file, fileEncoding = "Shift-JIS")  # 指定文件编码
    data$Date <- folder_date  # 添加日期列
    return(data)
  } else {
    return(NULL)  # 如果没有找到文件或有多个文件，不处理
  }
}

# 遍历所有文件夹并合并所有的 3_Summary 数据
all_data <- folders %>%
  map_dfr(process_folder)
print(all_data)
write.csv(all_data, "/Users/liaojiajia/博士研究/NIES/富士/求和", row.names = FALSE)

# 将 Date 列转换为标准日期格式
all_data <- all_data %>%
  mutate(Date = ymd(Date))  

# 过滤出“期間全体”的数据
all_data_filtered <- all_data %>%
  filter(富士山吉田登山口 == "期間全体")

# 计算每一行的男性和女性总和，以及各年龄段的总和
all_data_filtered <- all_data_filtered %>%
  mutate(
    Male_Female_Sum = 男性 + 女性,  
    Generation_Sum = X20代 + X30代 + X40代 + X50代 + X60代 + X70歳以上  
  )

# 取较大值作为当天的总游客数
# 首先按日期分组，并计算每日的总和
daily_totals <- all_data_filtered %>%
  group_by(Date) %>%
  summarise(
    Daily_Male_Female_Sum = sum(Male_Female_Sum, na.rm = TRUE), 
    Daily_Generation_Sum = sum(Generation_Sum, na.rm = TRUE)     
  ) %>%
  mutate(Daily_Total_Visitors = pmax(Daily_Male_Female_Sum, Daily_Generation_Sum, na.rm = TRUE))
all_data_filtered <- all_data_filtered %>%
  left_join(daily_totals %>% select(Date, Daily_Total_Visitors), by = "Date")


total_visitors_month <- sum(daily_totals$Daily_Total_Visitors, na.rm = TRUE)
print(head(all_data_filtered))
write.csv(all_data_filtered, "/Users/liaojiajia/博士研究/NIES/富士/求和/filtered_summary_with_totals.csv", row.names = FALSE)



########################### KDDI VS MOE correlation test
official_data <- read.csv("/Users/liaojiajia/Downloads/moe_count.csv")  
user_data <- read.csv("/Users/liaojiajia/博士研究/NIES/富士/求和/daily_totals_july_2023.csv")  
official_data$date <- as.Date(official_data$date, format = "%Y-%m-%d") 
user_data$Date <- as.Date(user_data$Date)  

official_july_2023 <- official_data %>%
  filter(year(date) == 2023 & month(date) == 7)

user_july_2023 <- user_data %>%
  filter(year(Date) == 2023 & month(Date) == 7)

merged_data <- merge(user_july_2023, official_july_2023, by.x = "Date", by.y = "date")
print(head(merged_data))

#正态性检验
shapiro.test(merged_data$Daily_Total_Visitors)
shapiro.test(merged_data$yoshida)
plot(merged_data$Daily_Total_Visitors, merged_data$yoshida, main="Scatter Plot", xlab="Your Data", ylab="Official Data")

# Spearman 相关系数
correlation_spearman <- cor(merged_data$Daily_Total_Visitors, merged_data$yoshida, method = "spearman", use = "complete.obs")

print(paste("The Spearman correlation between Daily_Total_Visitors and Yoshida for July 2023 is:", correlation_spearman))
ggplot(merged_data, aes(x = Daily_Total_Visitors, y = yoshida)) +
  geom_point(color = "blue", alpha = 0.6) +  
  geom_smooth(method = "lm", color = "red", se = FALSE) +  
  labs(
    title = "Scatter Plot of Daily Total Visitors vs Yoshida (July 2023)",
    x = "Your Data: Daily Total Visitors",
    y = "Official Data: Yoshida Visitors"
  ) +
  theme_minimal()  
















