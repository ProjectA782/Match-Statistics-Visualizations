# Attach required libraries
library(stringr)
library(ggplot2)
library(dplyr)
library(tidyr)

# Read the CSV file
df <- read.csv("mps.csv")

# Apply the conversion and replacement logic to df$Value
df$Value <- sapply(df$Value, function(x) {
  numeric_value <- suppressWarnings(as.numeric(x)) # Attempt to convert to numeric
  if (is.na(numeric_value)) {
    return(NaN) # Replace non-convertible values with NaN
  } else {
    return(numeric_value) # Keep the numeric value
  }
})

# Drop rows with NA values
df <- df %>%
  drop_na()

# Change df$Value to numeric
df$Value <- as.numeric(df$Value)

# Compute total goals scored at home and away for each country
goals_home_away <- df %>%
  filter(StatsName == "Goals") %>%
  
  # Aggregate home goals
  group_by(HomeTeamName) %>%
  summarize(HomeGoals = sum(Value, na.rm = TRUE), .groups = "drop") %>%
  rename(Country = HomeTeamName) %>%
  
  # Join with away goals
  full_join(
    df %>%
      filter(StatsName == "Goals") %>%
      group_by(AwayTeamName) %>%
      summarize(AwayGoals = sum(Value, na.rm = TRUE), .groups = "drop") %>%
      rename(Country = AwayTeamName),
    by = "Country"
  ) %>%
  
  # Replace NA with 0
  mutate(
    HomeGoals = coalesce(HomeGoals, 0),
    AwayGoals = coalesce(AwayGoals, 0)
  ) %>%
  pivot_longer(
    cols = c(HomeGoals, AwayGoals),
    names_to = "Location",
    values_to = "TotalGoals"
  ) %>%
  
  # Ensure stacking order
  mutate(Location = factor(Location, levels = c("AwayGoals", "HomeGoals")))

# Create stacked bar chart
stacked_bar <- ggplot(goals_home_away, aes(x = reorder(Country, -TotalGoals), y = TotalGoals, fill = Location)) +
  geom_bar(stat = "identity", position = "stack", color = "black", width = 0.5) +
  theme_minimal() +
  scale_fill_manual(
    values = c("AwayGoals" = "#a0faf5", "HomeGoals" = "#035954"),
    labels = c("Away Goals", "Home Goals")
  ) +
  labs(
    title = "Goals Scored at Home and Away by Country (Stacked)",
    x = "Country",
    y = "Total Goals",
    fill = "Location"
  ) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    plot.title = element_text(hjust = 0.5, size = 16),
    axis.ticks.x = element_blank(),
    panel.grid.major.x = element_blank(),
    panel.grid.minor.x = element_blank(),
    panel.background = element_rect(fill = "#f0f0f0", color = NA), # Grayish background
    plot.background = element_rect(fill = "white", color = NA), # Light gray border
    legend.background = element_rect(fill = "#f0f0f0", color = NA),
    plot.margin = margin(20, 20, 20, 20) # Increased spacing around the plot
  ) +
  scale_x_discrete(expand = expansion(add = 1)) # Add spacing between bars

stacked_bar

# Initialize an empty list to store factor data
factors <- list()

# Loop through unique values of StatsName and process data
for (factor in unique(df$StatsName)) {
  # Filter the data for the current factor and group by MatchID
  data <- df %>%
    filter(StatsName == factor) %>%
    group_by(MatchID) %>%
    summarize(Value = sum(Value, na.rm = TRUE), .groups = 'drop') %>%
    rename(!!factor := Value)
  
  # Append the processed data to the list
  factors[[factor]] <- data
}

# Combine all factor data into one data frame, aligning by MatchID
data <- Reduce(function(x, y) full_join(x, y, by = "MatchID"), factors)

# Ensure all necessary columns exist before calculating correlations
data <- data %>% drop_na()  # Drop rows with any NA values to strictly align data

# Check if "Goals" column exists
if (!"Goals" %in% colnames(data)) {
  stop("The column 'Goals' does not exist in the combined data.")
}

# Remove MatchID column for correlation calculation
data_no_matchid <- data %>% select(-MatchID)

# Remove columns with zero variance
data_no_matchid <- data_no_matchid %>%
  select(where(~ var(.) > 0))


# Recheck if "Goals" still exists after removing zero-variance columns
if (!"Goals" %in% colnames(data_no_matchid)) {
  stop("The column 'Goals' was removed due to zero variance.")
}

# Calculate the correlation matrix with pairwise complete observations
corr_matrix <- cor(data_no_matchid, use = "pairwise.complete.obs", method = "pearson")

# Convert the correlation matrix to a data frame
corr_df <- as.data.frame(corr_matrix)

# Add row names as a column for filtering
corr_df <- corr_df %>%
  mutate(StatName = rownames(corr_df)) %>%
  select(StatName, everything())

# Filter out rows whose StatName contains the word "Goals" and extract the "Goals" column
goals_corr <- corr_df %>%
  filter(!grepl("Goals", StatName)) %>%  # Exclude rows with "Goals" in their name
  select(StatName, Goals) %>%            # Extract the "Goals" column
  arrange(desc(Goals)) %>%               # Sort by correlation with "Goals"
  filter(Goals >= 0.3)                   # Filter for correlations >= 0.3


# Create a line chart for goals_corr
ggplot(goals_corr, aes(x = reorder(rownames(goals_corr), Goals), y = Goals, group = 1)) +
  geom_line(color = "#035954", linewidth = 1) +  # Dark green for the line
  geom_point(color = "#035954", size = 1) +      # Light blue for points
  labs(
    title = "Correlations between match stats and goals",
    x = "Match Statistics",
    y = "Correlation with goals"
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 135, hjust = 1),
    plot.title = element_text(hjust = 0.5, size = 16),
    panel.grid.major.x = element_blank(),
    panel.grid.minor.x = element_blank(),
    panel.background = element_rect(fill = "#f0f0f0", color = NA),  # Grayish background
    plot.background = element_rect(fill = "white", color = NA),     # Light gray border
    plot.margin = margin(20, 20, 20, 20)  # Increased spacing around the plot
  ) +
  theme(aspect.ratio = 0.4)  # Adjust height-to-width ratio


# Create a scatter plot for Goals vs Assists with a trend line
ggplot(data, aes(x = Goals, y = Assists)) +
  geom_point(color = "#035954", size = 3, alpha = 0.8) +  # Dark green points
  geom_smooth(method = "lm", color = "#000a0a", linewidth = 1, se = FALSE) +  # Light blue trend line
  labs(
    title = "Scatter Plot of Goals vs Assists with Trend Line",
    x = "Goals",
    y = "Assists"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5, size = 16),
    panel.grid.major = element_line(color = "#d3d3d3"),
    panel.grid.minor = element_blank(),
    panel.background = element_rect(fill = "#f0f0f0", color = NA),  # Grayish background
    plot.background = element_rect(fill = "white", color = NA)  # Light gray border
  )

# Step 1: Filter data to create assist_df where StatsName == "Assists"
assist_df <- df %>%
  filter(StatsName == "Assists")

# Step 2: Create FullName column by combining PlayerName and PlayerSurname
assist_df <- assist_df %>%
  mutate(FullName = paste(PlayerName, PlayerSurname))

# Step 3: Group by FullName and sum up the Value column for each player
grouped_assist_df <- assist_df %>%
  group_by(FullName) %>%
  summarize(TotalAssists = sum(Value, na.rm = TRUE), .groups = "drop")

# Step 4: Filter players whose total assists are 2 or more
filtered_assist_df <- grouped_assist_df %>%
  filter(TotalAssists >= 2)

# Step 5: Plot a horizontal bar chart
ggplot(filtered_assist_df, aes(x = reorder(FullName, TotalAssists), y = TotalAssists)) +
  geom_bar(stat = "identity", fill = "#035954", color = "black", width = 0.6) +  # Use dark green for bars
  coord_flip() +  # Make the bar chart horizontal
  labs(
    title = "Players with 2 or More Assists",
    x = "Player",
    y = "Total Assists"
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(hjust = 1),
    plot.title = element_text(hjust = 0.5, size = 16),
    axis.ticks.x = element_blank(),
    panel.grid.major.x = element_blank(),
    panel.grid.minor.x = element_blank(),
    panel.background = element_rect(fill = "#f0f0f0", color = NA),  # Grayish background
    plot.background = element_rect(fill = "white", color = NA),  # Light gray border
    plot.margin = margin(20, 20, 20, 20)  # Increased spacing around the plot
  )

