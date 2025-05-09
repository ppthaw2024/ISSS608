---
  title: "Take-home Exercise 4 updated for Project"
subtitle: "Prototyping Modules for Visual Analytics Shiny Application"
author: "Lim Jia Jia"
date: March 22, 2024
date-modified: "last-modified"
execute: 
  eval: true
echo: true
warning: false
toc: true
format: 
  html:
  code-fold: false
---
  
  ## Overview
  
  In this take-home exercise, we are required to select one of the module of our proposed Shiny application and complete the following tasks:
  
  -   To evaluate and determine the necessary R packages needed for your Shiny application are supported in R CRAN,
-   To prepare and test the specific R codes can be run and returned the correct output as expected,
-   To determine the parameters and outputs that will be exposed on the Shiny applications, and
-   To select the appropriate Shiny UI components for exposing the parameters determine above.

The module that we are focusing on is the univariate forecasting of the data.

## Loading R packages

First and foremost, we will start by loading the R packages required.

```{r}
pacman::p_load(tidyverse, ggplot2, tsibble, tsibbledata,  
               fable, fabletools, feasts, 
               plotly, DT, fable.prophet)
```

## Data preparation

As this take home exercise serves as analysis of one of the module of the project, the data preparation steps is only performed once to ensure that same data set **(weather_imputed_11stations.rds)** are used across all members. Detailed preparation steps can be found in this [link](https://isss608-group9-weatheranalytics.netlify.app/code/data_preparation_weather).

### Importing the data

We import the processed data set using `read_rds()`,

```{r}
weather <- read_rds("data/weather_imputed_11stations.rds")
```

```{r}
head(weather)
```

### Convert to tsibble data frame

The dataset comprises daily records of rainfall and temperature gathered from various weather stations across Singapore. Initially, this data is loaded in a 'tibble' format. However, for our forecasting analysis, we will be using [**fable**](https://fable.tidyverts.org/) package, which is part of the [tidyverts](https://tidyverts.org/) ecosystem and requires data in a ['tsibble'](https://tsibble.tidyverts.org/) format. To accommodate this requirement, we will convert our tibble dataframe into a tsibble using the following code.

```{r}
weather_tsbl <- as_tsibble(weather, key = Station, index = Date)
weather_tsbl
```

The list below shows 11 unique stations.

```{r}
Station <- weather_tsbl %>% distinct(Station)

datatable(Station, 
          class= "compact",
          rownames = FALSE,
          width="100%", 
          options = list(pageLength = 12,scrollX=T))
```

::: {.focusbox .focus data-latex="focus"}
**What is tsibble?**
  
  A tsibble consists of a time index, key, and other measured variables in a data-centric format. In tsibble,

-   Index is a variable with inherent ordering from past to present.
-   Key is a set of variables that define observational units over time.
-   Each observation should be uniquely identified by index and key.
-   Each observational unit should be measured at a common interval, if regularly spaced.
:::
  
  ## Section 1: Time Series Exploration
  
  In this section, users can interactively explore time series data using a line graph equipped with a time slider. They have the option to select specific stations, variables, and time periods for analysis.

```{r}
# user defined parameter
selected_stations <- unique(weather_tsbl$Station)
variable_temp <- "Minimum Temperature (°C)"
variable_rain <- "Daily Rainfall Total (mm)"
start_date <- "2021-01-01"
end_date <-  "2023-12-31"

```

::: panel-tabset
#### Temp; Daily

```{r}
# Filter data based on period
filtered_period <- weather_tsbl %>%
  filter_index(start_date ~ end_date)

# Filter period-filtered data based on multiple selected stations
filtered_period_mstn <- filtered_period  %>%
  filter(Station %in% selected_stations) 

# Generate the plot based on filtered data
plot_ly(filtered_period_mstn, 
        x = ~Date, 
        y = as.formula(paste0("~`", variable_temp, "`")), 
        type = 'scatter', 
        mode = 'lines', 
        color = ~Station,
        hoverinfo = 'text',
        text = ~paste("<b>Station:</b>", Station,
                      "<br><b>Date:</b>", Date,
                      "<br><b>", variable_temp, ":</b>", filtered_period_mstn[[variable_temp]])) %>%
  layout(title = paste(variable_temp, "by Station"),
         xaxis = list(title = ""),
         yaxis = list(title = "")) %>%
  
  # Display the plot
  layout(xaxis = list(rangeslider = list(type = "date"))) 

```

#### Temp; weekly average

The code chunk below plot line graph for weekly summarise view of the following variables: "Mean Temperature (°C)", "Minimum Temperature (°C)", "Maximum Temperature (°C)"

```{r}
# Summarise period-filtered temperature data based on weekly average
summarised_temp_week <- filtered_period %>%
  group_by_key() %>%
  index_by(year_week = ~ yearweek(.)) %>%
  summarise(
    avg_temp = round(mean(.data[[variable_temp]]),2), na.rm = TRUE)

# Filter summarised temperature data based on multiple selected stations
summarised_temp_mstn <- summarised_temp_week  %>%
  filter(Station %in% selected_stations) 
```

```{r}
# Convert the year_week result to the first day of the week for plotting
summarised_temp_mstn <- summarised_temp_mstn %>%
  mutate(week_start_date = floor_date(as.Date(year_week), unit = "week"))

# Generate the plot based on filtered data
plot_ly(summarised_temp_mstn, x = ~week_start_date, y = ~avg_temp,
        type = 'scatter', mode = 'lines', color = ~Station,
        hoverinfo = 'text',
        text = ~paste("<b>Station:</b>", Station, 
                      "<br><b>Week Starting:</b>", week_start_date, 
                      "<br><b>Average", variable_temp, ":</b>", avg_temp)) %>%
  
  layout(title = paste("Weekly Average", variable_temp, "by Station"),
         xaxis = list(title = ""),
         yaxis = list(title = "")) %>%
  
  # Display the plot
  layout(xaxis = list(rangeslider = list(type = "date"))) 

```

#### Temp; monthly average

Line graph for monthly summarise view of the following variables: "Mean Temperature (°C)", "Minimum Temperature (°C)", "Maximum Temperature (°C)"

```{r}
# Summarise period-filtered temperature data based on monthly average
summarised_temp_month <- filtered_period %>%
  group_by_key() %>%
  index_by(year_month = ~ yearmonth(.)) %>%
  summarise(
    avg_temp = round(mean(.data[[variable_temp]]),2), na.rm = TRUE)

# Filter summarised temperature data based on multiple selected stations
summarised_temp_mstn <- summarised_temp_month  %>%
  filter(Station %in% selected_stations) 
```

```{r}
# Convert the year_week result to the first day of the week for plotting
summarised_temp_mstn <- summarised_temp_mstn %>%
  mutate(month_start_date = floor_date(as.Date(year_month), unit = "month"))

# Generate the plot based on filtered data
plot_ly(summarised_temp_mstn, x = ~month_start_date, y = ~avg_temp,
        type = 'scatter', mode = 'lines', color = ~Station,
        hoverinfo = 'text',
        text = ~paste("<b>Station:</b>", Station, 
                      "<br><b>Month:</b>", year_month, 
                      "<br><b>Average", variable_temp, ":</b>", avg_temp)) %>%
  
  layout(title = paste("Monthly Average", variable_temp, "by Station"),
         xaxis = list(title = ""),
         yaxis = list(title = "")) %>%
  
  # Display the plot
  layout(xaxis = list(rangeslider = list(type = "date"))) 

```

#### Rain; weekly total

Variable - Daily Rainfall Total (mm) Time resolution - week

```{r}
# Summarise period-filtered rainfall data based on weekly total
summarised_rain_week <- filtered_period %>%
  group_by_key() %>%
  index_by(year_week = ~ yearweek(.)) %>%
  summarise(
    total_rainfall = sum(.data[[variable_rain]]), na.rm = TRUE)

# Filter summarised rainfall data based on multiple selected stations
summarised_rain_mstn <- summarised_rain_week  %>%
  filter(Station %in% selected_stations) 
```

```{r}
# Convert the year_week result to the first day of the week for plotting
summarised_rain_mstn <- summarised_rain_mstn %>%
  mutate(week_start_date = floor_date(as.Date(year_week), unit = "week"))

# Generate the plot based on filtered data
plot_ly(summarised_rain_mstn, x = ~week_start_date, y = ~total_rainfall,
        type = 'scatter', mode = 'lines', color = ~Station,
        hoverinfo = 'text',
        text = ~paste("<b>Station:</b>", Station, 
                      "<br><b>Week Starting:</b>", week_start_date, 
                      "<br><b>Total rainfall :</b>", total_rainfall, "mm")) %>%
  
  layout(title = paste("Weekly", variable_rain, "by Station"),
         xaxis = list(title = ""),
         yaxis = list(title = "")) %>% 
  
  # Display the plot
  layout(xaxis = list(rangeslider = list(type = "date"))) 

```

#### Rain; monthly total

Variable - Daily Rainfall Total (mm) Time resolution - Month

```{r}
# Summarise period-filtered rainfall data based on weekly total
summarised_rain_month <- filtered_period %>%
  group_by_key() %>%
  index_by(year_month = ~ yearmonth(.)) %>%
  summarise(
    total_rainfall = sum(.data[[variable_rain]]), na.rm = TRUE)

# Filter summarised rainfall data based on multiple selected stations
summarised_rain_mstn <- summarised_rain_month  %>%
  filter(Station %in% selected_stations) 
```

```{r}
# Convert the year_week result to the first day of the week for plotting
summarised_rain_mstn <- summarised_rain_mstn %>%
  mutate(month_start_date = floor_date(as.Date(year_month), unit = "month"))

# Generate the plot based on filtered data
plot_ly(summarised_rain_mstn, x = ~~month_start_date, y = ~total_rainfall,
        type = 'scatter', mode = 'lines', color = ~Station,
        hoverinfo = 'text',
        text = ~paste("<b>Station:</b>", Station, 
                      "<br><b>Month:</b>", year_month, 
                      "<br><b>Total rainfall :</b>", total_rainfall, "mm")) %>%
  
  layout(title = paste("Monthly", variable_rain, "by Station"),
         xaxis = list(title = ""),
         yaxis = list(title = "")) %>% 
  
  # Display the plot
  layout(xaxis = list(rangeslider = list(type = "date"))) 

```
:::
  
  ## Section 2: Time Series Decomposition and auto correlation
  
  This section introduces the STL method, a versatile and robust method that breaks down time series data into trend, seasonality, and remainder components.

STL is an acronym for “Seasonal and Trend decomposition using Loess”, while loess is a method for estimating nonlinear relationships. We will use STL to uncover deeper insights into our data, highlighting its importance in understanding and predicting trends.

Below are the sample plot of STL decomposition using different tuning parameter.

### ACF & PACF

ACF(Autocorrelation function) measures the linear relationship between lagged values of a time series while PACF (Partial Autocorrelation Function) measures the correlation between observations with the effect of the intermediate observations removed. In this section, users can view the ACF and PACF to analyze the time-dependent characteristics of the selected time series data.

Users can choose a single station to generate the ACF and PACF plot. For the purpose of this exercise, we demonstrate using "Ang Mo Kio" station.

```{r}
single_station <- "Ang Mo Kio"
```

::: panel-tabset
### ACF, daily

```{r}
filtered_period_sstn <- filtered_period  %>%
  filter(Station %in% single_station) 

ACF <- filtered_period_sstn %>%
  ACF(filtered_period_sstn[[variable_temp]], lag_max = 100) %>%
  autoplot() +
  labs(title = paste("ACF plot of", variable_temp, "for", single_station)) +
  theme_minimal()

ggplotly(ACF)
```

### ACF, weekly average temperature

```{r}
summarised_temp_week_sstn <- summarised_temp_week   %>%
  filter(Station %in% single_station) 


ACF <- summarised_temp_week_sstn %>%
  ACF(avg_temp, lag_max = 50) %>%
  autoplot() +
  labs(title = paste("ACF plot of Weekly", variable_temp, "for", single_station)) +
  theme_minimal()

ggplotly(ACF)
```
:::
  
  ::: panel-tabset
### PACF, daily

```{r}
filtered_period_sstn <- filtered_period  %>%
  filter(Station %in% single_station) 

PACF <- filtered_period_sstn %>%
  PACF(filtered_period_sstn[[variable_temp]], lag_max = 100) %>%
  autoplot() +
  labs(title = paste("PACF plot of", variable_temp, "for", single_station)) +
  theme_minimal()

ggplotly(PACF)
```

### PACF, weekly total rainfall

```{r}
summarised_rain_week_sstn <- summarised_rain_week  %>%
  filter(Station %in% single_station) 


PACF <- summarised_rain_week_sstn %>%
  PACF(total_rainfall, lag_max = 50) %>%
  autoplot() +
  labs(title = paste("PACF plot of Weekly", variable_rain, "for", single_station)) +
  theme_minimal()

ggplotly(PACF)
```
:::
  
  ### STL Decomposition analysis
  
  ```{r}
single_station <- "Ang Mo Kio"

filtered_period_sstn <- filtered_period  %>%
  filter(Station %in% single_station) 
```

```{r}
stl_formula_default <- STL(`Mean Temperature (°C)`)

stl_formula_min <- STL(`Mean Temperature (°C)`
                       ~ trend(window = 1) +        
                         ~  season(window = 1))
stl_formula_max <- STL(`Mean Temperature (°C)`
                       ~ trend(window = 365) +        
                         ~  season(window = 365))
```

::: panel-tabset
#### Auto STL

```{r}
stl_default <- filtered_period_sstn %>%
  model(stl_formula_default) %>%
  components() 
```

```{r}
stl_default_tibble <- as_tibble(stl_default) %>%
  select(Date, `Mean Temperature (°C)`, trend, season_week, season_year, remainder, season_adjust) %>%
  mutate(trend = round(trend, 2),
         season_adjust = round(season_adjust, 2),
         season_week = round(season_week, 4),
         season_year = round(season_year, 4),
         remainder = round(remainder, 4))

datatable(stl_default_tibble, 
          class= "nowrap", 
          rownames = FALSE, 
          filter = 'top',  # Enables filters at the top of each column
          width="100%", 
          options = list(pageLength = 10, scrollX = TRUE))
```

```{r}
plot_stl_default <- stl_default %>%
  autoplot()

ggplotly(plot_stl_default) %>% layout(width = 700, height = 700, 
                                      plot_bgcolor="#edf2f7")
```

#### Min STL

```{r}
stl_min <- filtered_period_sstn %>%
  model(stl_formula_min) %>%
  components()
```

```{r}
stl_min_tibble <- as_tibble(stl_min) %>%
  select(Date, `Mean Temperature (°C)`, trend, season_week, season_year, remainder, season_adjust) %>%
  mutate(trend = round(trend, 2),
         season_adjust = round(season_adjust, 2),
         season_week = round(season_week, 4),
         season_year = round(season_year, 4),
         remainder = round(remainder, 4))

datatable(stl_min_tibble, 
          class= "nowrap", 
          rownames = FALSE, 
          filter = 'top',  # Enables filters at the top of each column
          width="100%", 
          options = list(pageLength = 10, scrollX = TRUE))
```

```{r}
plot_stl_min <- stl_min %>%
  autoplot()

ggplotly(plot_stl_min) %>% layout(width = 700, height = 700, 
                                  plot_bgcolor="#edf2f7")
```

#### Max STL

```{r}
stl_max <- filtered_period_sstn %>%
  model(stl_formula_max) %>%
  components()
```

```{r}
stl_max_tibble <- as_tibble(stl_max) %>%
  select(Date, `Mean Temperature (°C)`, trend, season_week, season_year, remainder, season_adjust) %>%
  mutate(trend = round(trend, 2),
         season_adjust = round(season_adjust, 2),
         season_week = round(season_week, 4),
         season_year = round(season_year, 4),
         remainder = round(remainder, 4))

datatable(stl_max_tibble, 
          class= "nowrap", 
          rownames = FALSE, 
          filter = 'top',  # Enables filters at the top of each column
          width="100%", 
          options = list(pageLength = 10, scrollX = TRUE))
```

```{r}
plot_stl_max <- stl_max %>%
  autoplot()

ggplotly(plot_stl_max) %>% layout(width = 700, height = 700, 
                                  plot_bgcolor="#edf2f7")
```
:::
  
  The STL decomposition plot consist of four panel. The bottom four panel shows breakdown of three components of STL, namely trend, seasonality, and remainder. These components can be added together to reconstruct the data shown in the top panel. The remainder component shown in the bottom panel is what is left over when the seasonal and trend-cycle components have been subtracted from the data.

#### STL test case

The below test case is run using the default STL formula.

::: panel-tabset
#### Temperature; weekly average

```{r}
stl_temp_week <- summarised_temp_week_sstn %>%
  model(STL(avg_temp)) %>%
  components() 
```

```{r}
plot_stl_default <- stl_temp_week %>%
  autoplot()

ggplotly(plot_stl_default) %>% layout(width = 700, height = 700, 
                                      plot_bgcolor="#edf2f7")
```

#### Rainfall; weekly total

```{r}
stl_rain_week <- summarised_rain_week_sstn %>%
  model(STL(total_rainfall)) %>%
  components() 
```

```{r}
plot_stl_default <- stl_rain_week %>%
  autoplot()

ggplotly(plot_stl_default) %>% layout(width = 700, height = 700, 
                                      plot_bgcolor="#edf2f7")
```
:::
  
  ### New plot to consider (ignore this part)
  
  This plot do not show the correct label.

```{r}
gg_season_plot <- filtered_period_sstn %>%
  gg_season(`Mean Temperature (°C)`) +
  theme_minimal()
```

```{r}
gg_season_plot
```

```{r}
ggplotly(gg_season_plot)
```

```{r}
gg_tsdisplay(filtered_period_sstn, `Mean Temperature (°C)`, plot_type = "auto")
```

The below plot is not appropriate, since we only have 3 years of data.

```{r}
# Summarise period-filtered temperature data based on weekly average
summarised_temp <- filtered_period %>%
  group_by_key() %>%
  index_by(year_month = ~ yearmonth(.)) %>%
  summarise(
    avg_temp = round(mean(.data[[variable_temp]]),2), na.rm = TRUE)

# Filter summarised temperature data based on multiple selected stations
summarised_temp_sstn <- summarised_temp  %>%
  filter(Station %in% single_station) 


```

```{r}
summarised_temp_sstn
```

```{r}
summarised_temp_sstn %>% gg_subseries(avg_temp)
```

## Section 3: Time Series Forecasting \[daily\]

### Split data into training and testing

```{r}
# Define the split point; for example, keeping the first 80% of rows for training
split_point <- nrow(filtered_period_sstn) * 0.8

# Create the training dataset (first 80% of the data)
train_daily <- filtered_period_sstn %>% 
  slice(1:floor(split_point))

# Create the test dataset (remaining 20% of the data)
test_daily <- filtered_period_sstn %>% 
  slice((floor(split_point) + 1):n())
```

### Create and fit multiple model to tesing set

We observed that our data exhibits seasonal patterns, and hence we select the models specifically designed to handle such seasonal variations.

```{r}
train_daily_fit <- train_daily %>%
  model(
    # naïve forecast of the seasonally adjusted data
    STLNaive = decomposition_model(stl_formula_default, NAIVE(season_adjust)),              
    
    # auto arima forecast of the seasonally adjusted data
    STLArima = decomposition_model(stl_formula_default, ARIMA(season_adjust)),
    
    # Exponential Smoothing forecast of the seasonally adjusted data
    STLETS = decomposition_model(stl_formula_default, ETS(season_adjust ~ season("N"))),
    
    # AUTO arima
    AUTOARIMA = ARIMA(`Mean Temperature (°C)`),    
    
    # AUTO prophet
    AUTOprophet = prophet(`Mean Temperature (°C)`),
    
    # Auto Exponential smoothing
    AUTOETS = ETS(`Mean Temperature (°C)`)
  )

forecast_horizon <- nrow(test_daily)

# Forecasting
train_daily_fc <- forecast(train_daily_fit, h = forecast_horizon)

# Plotting the forecasts
c <- autoplot(train_daily, `Mean Temperature (°C)`) +
  autolayer(test_daily, `Mean Temperature (°C)`, series = "Test Data") +
  autolayer(train_daily_fc, level = NULL) +
  labs(title = "Forecast Validation for daily mean temperature of Ang Mo Kio Station") +
  theme_minimal() 

ggplotly(c, tooltip = c("x", "y", ".model"))
```

### Testing set forcast & Accuracy Evaluation

```{r}
accuracy_metrics <- accuracy(train_daily_fc, test_daily) %>%
  arrange(.model) %>%
  select(.model, .type, RMSE, MAE, MAPE, MASE) %>%
  mutate(across(c(RMSE, MAE, MAPE, MASE), round, 2))

datatable(accuracy_metrics, 
          class= "hover",
          rownames = FALSE,
          width="100%", 
          options = list(pageLength = 10,scrollX=T))
```

#### Residual plot

```{r}
residual <- train_daily %>%
  model(
    # naïve forecast of the seasonally adjusted data
    STLNaive = decomposition_model(stl_formula_default, NAIVE(season_adjust)),              
    
    # auto arima forecast of the seasonally adjusted data
    STLArima = decomposition_model(stl_formula_default, ARIMA(season_adjust)),
    
    # Exponential Smoothing forecast of the seasonally adjusted data
    STLETS = decomposition_model(stl_formula_default, ETS(season_adjust ~ season("N"))),
    
    # AUTO arima
    AUTOARIMA = ARIMA(`Mean Temperature (°C)`),    
    
    # AUTO prophet
    AUTOprophet = prophet(`Mean Temperature (°C)`),
    
    # Auto Exponential smoothing
    AUTOETS = ETS(`Mean Temperature (°C)`)
  ) %>% 
  augment() 

a <- autoplot(residual, .innov) +  
  labs(title = "Residual Plot") +
  theme_minimal() 

ggplotly(a)
```

### Refit to Full Dataset & Forecast Forward

```{r}
# Refit models to the full dataset
full_fit <- filtered_period_sstn %>%
  model(
    # naïve forecast of the seasonally adjusted data
    STLNaive = decomposition_model(stl_formula_default, NAIVE(season_adjust)),              
    
    # auto arima forecast of the seasonally adjusted data
    STLArima = decomposition_model(stl_formula_default, ARIMA(season_adjust)),
    
    # Exponential Smoothing forecast of the seasonally adjusted data
    STLETS = decomposition_model(stl_formula_default, ETS(season_adjust ~ season("N"))),
    
    # AUTO arima
    AUTOARIMA = ARIMA(`Mean Temperature (°C)`),    
    
    # AUTO prophet
    AUTOprophet = prophet(`Mean Temperature (°C)`),
    
    # Auto Exponential smoothing
    AUTOETS = ETS(`Mean Temperature (°C)`)
  )
```

```{r}
future_horizon <- "1 month" # Adjust this to your forecast needs
full_forecast <- forecast(full_fit, h = future_horizon)
```

```{r}
full_forecast_df <- as_tibble(full_forecast)

full_forecast_df <- full_forecast_df %>%
  mutate(.mean = round(.mean, 2)) %>%
  mutate(n=n(), sd=sd(.mean)) %>%
  mutate(se=sd/sqrt(n-1)) %>%
  mutate(Lower = round(.mean - (1.96 * se), 2),
         Upper = round(.mean + (1.96 * se), 2))
```

```{r}
# Initialize an empty plotly object
p <- plot_ly()

# Unique models for iteration and color assignment
unique_models <- unique(full_forecast_df$.model)
colors <- RColorBrewer::brewer.pal(n = length(unique_models), name = "Set1")

# Loop through each model to add to the plot
for (i in seq_along(unique_models)) {
  model_name <- unique_models[i]
  
  # Filter data for the current model
  model_data <- filter(full_forecast_df, .model == model_name)
  
  # Define the custom hovertemplate for lines
  hovertemplate_line <- paste(
    "Date: %{x}<br>",
    "Mean Temperature (°C): %{y:.2f}<br>",
    "Model: ", model_name, "<br>",
    "95% CI: [%{customdata[0]:.2f}, %{customdata[1]:.2f}]<extra></extra>"
  )
  
  # Customdata for the line (lower and upper CI values)
  custom_data <- mapply(function(lower, upper) list(lower, upper), model_data$Lower, model_data$Upper, SIMPLIFY = FALSE)
  
  # Add forecast line with custom tooltip and legend grouping
  p <- add_lines(p, data = model_data, x = ~Date, y = ~`.mean`, name = model_name,
                 line = list(color = colors[i]), hovertemplate = hovertemplate_line,
                 customdata = custom_data, legendgroup = model_name)
  
  # Add confidence interval ribbon with legend grouping, but no separate legend entry
  p <- add_ribbons(p, data = model_data, x = ~Date, ymin = ~Lower, ymax = ~Upper,
                   fillcolor = scales::alpha(colors[i], 0.2), line = list(color = "transparent"),
                   legendgroup = model_name, showlegend = FALSE, hoverinfo = "skip")
}

# Customize layout
p <- p %>% layout(title = "Future Forecast Plot with 95% CI for daily mean temperature of Ang Mo Kio Station",
                  xaxis = list(title = "Date"),
                  yaxis = list(title = "Mean Temperature (°C)"),
                  legend = list(title = list(text = 'Model')),
                  hovermode = 'closest')

# Display the plot
p
```

```{r}
# Table view
col<- full_forecast_df %>% 
  select(.model, Date, .mean) %>% 
  rename(Forecast = .mean) %>%
  mutate(Forecast = round(Forecast, 2),
         .model = as.factor(.model))


datatable(col, 
          class= "hover", 
          rownames = FALSE, 
          filter = 'top',  # Enables filters at the top of each column
          width="100%", 
          options = list(pageLength = 6, scrollX = TRUE))

```

## Section 3.1: Time Series Forecasting \[Temperature-weekly average\]

### Split data into training and testing

```{r}
# Define the split point; for example, keeping the first 80% of rows for training
split_point <- nrow(summarised_temp_week_sstn) * 0.8

# Create the training dataset (first 80% of the data)
train_temp_week <- summarised_temp_week_sstn %>% 
  slice(1:floor(split_point))

# Create the test dataset (remaining 20% of the data)
test_temp_week <- summarised_temp_week_sstn %>% 
  slice((floor(split_point) + 1):n())
```

### Create and fit multiple model to tesing set

We observed that our data exhibits seasonal patterns, and hence we select the models specifically designed to handle such seasonal variations.

```{r}
train_temp_week_fit <- train_temp_week %>%
  model(
    # naïve forecast of the seasonally adjusted data
    STLNaive = decomposition_model(STL(avg_temp), NAIVE(season_adjust)),              
    
    # auto arima forecast of the seasonally adjusted data
    STLArima = decomposition_model(STL(avg_temp), ARIMA(season_adjust)),
    
    # Exponential Smoothing forecast of the seasonally adjusted data
    STLETS = decomposition_model(STL(avg_temp), ETS(season_adjust ~ season("N"))),
    
    # AUTO arima
    AUTOARIMA = ARIMA(avg_temp),    
    
    # AUTO prophet
    AUTOprophet = prophet(avg_temp),
    
    # Auto Exponential smoothing
    AUTOETS = ETS(avg_temp)
  )

forecast_horizon <- nrow(test_temp_week)

# Forecasting
train_temp_week_fc <- forecast(train_temp_week_fit, h = forecast_horizon)
```

```{r}
# Plotting the forecasts
c <- autoplot(train_temp_week, avg_temp) +
  autolayer(test_temp_week, avg_temp, series = "Test Data") +
  autolayer(train_temp_week_fc, level = NULL) +
  labs(title = "Forecast Validation for weekly mean temperature of Ang Mo Kio Station") +
  theme_minimal() 

ggplotly(c, tooltip = c("x", "y", ".model"))
```

### Testing set forcast & Accuracy Evaluation

```{r}
accuracy_metrics <- accuracy(train_temp_week_fc, test_temp_week) %>%
  arrange(.model) %>%
  select(.model, .type, RMSE, MAE, MAPE, MASE) %>%
  mutate(across(c(RMSE, MAE, MAPE, MASE), round, 2))

datatable(accuracy_metrics, 
          class= "hover",
          rownames = FALSE,
          width="100%", 
          options = list(pageLength = 10,scrollX=T))
```

#### Residual plot

```{r}
residual <- train_temp_week %>%
  model(
    # naïve forecast of the seasonally adjusted data
    STLNaive = decomposition_model(STL(avg_temp), NAIVE(season_adjust)),              
    
    # auto arima forecast of the seasonally adjusted data
    STLArima = decomposition_model(STL(avg_temp), ARIMA(season_adjust)),
    
    # Exponential Smoothing forecast of the seasonally adjusted data
    STLETS = decomposition_model(STL(avg_temp), ETS(season_adjust ~ season("N"))),
    
    # AUTO arima
    AUTOARIMA = ARIMA(avg_temp),    
    
    # AUTO prophet
    AUTOprophet = prophet(avg_temp),
    
    # Auto Exponential smoothing
    AUTOETS = ETS(avg_temp)
    
  )%>% 
  augment() 

a <- autoplot(residual, .innov) +
  labs(title = "Residual Plot") +
  theme_minimal() 

ggplotly(a)
```

### Refit to Full Dataset & Forecast Forward

```{r}
# Refit models to the full dataset
full_temp_week_fit <- summarised_temp_week_sstn %>%
  model(
    # naïve forecast of the seasonally adjusted data
    STLNaive = decomposition_model(STL(avg_temp), NAIVE(season_adjust)),              
    
    # auto arima forecast of the seasonally adjusted data
    STLArima = decomposition_model(STL(avg_temp), ARIMA(season_adjust)),
    
    # Exponential Smoothing forecast of the seasonally adjusted data
    STLETS = decomposition_model(STL(avg_temp), ETS(season_adjust ~ season("N"))),
    
    # AUTO arima
    AUTOARIMA = ARIMA(avg_temp),    
    
    # AUTO prophet
    AUTOprophet = prophet(avg_temp),
    
    # Auto Exponential smoothing
    AUTOETS = ETS(avg_temp)
    
  )

```

```{r}
# Plotting the forecasts along with the full dataset
future_horizon <- "10 week" # Adjust this to your forecast needs
full_temp_week_forecast <- forecast(full_temp_week_fit, h = future_horizon)
```

```{r}
e <- autoplot(full_temp_week_forecast, level = 95) +
  labs(title = "Future Forecast Plot for weekly mean temperature of Ang Mo Kio Station") +
  theme_minimal()

ggplotly(e, tooltip = c("x", "y",".model"))
```

```{r}
full_temp_week_forecast_tibble <- as_tibble(full_temp_week_forecast)

col <- full_temp_week_forecast_tibble %>% 
  mutate(year_week = paste(year(year_week), "w", 
                           sprintf("%02d", isoweek(year_week)), sep="")) %>%
  select(.model, year_week, .mean) %>% 
  rename(Forecast = .mean) %>%
  mutate(Forecast = round(Forecast, 2),
         .model = as.factor(.model),
         year_week = as.factor(year_week))

datatable(col, 
          class= "hover", 
          rownames = FALSE, 
          filter = 'top', 
          width="100%", 
          options = list(pageLength = 6, scrollX = TRUE))

```

## Section 3.2: Time Series Forecasting \[Rainfall-weekly total\]

### Split data into training and testing

```{r}
# Define the split point; for example, keeping the first 80% of rows for training
split_point <- nrow(summarised_rain_week_sstn) * 0.8

# Create the training dataset (first 80% of the data)
train_rain_week <- summarised_rain_week_sstn %>% 
  slice(1:floor(split_point))

# Create the test dataset (remaining 20% of the data)
test_rain_week <- summarised_rain_week_sstn %>% 
  slice((floor(split_point) + 1):n())
```

### Create and fit multiple model to tesing set

We observed that our data exhibits seasonal patterns, and hence we select the models specifically designed to handle such seasonal variations.

```{r}
train_rain_week_fit <- train_rain_week %>%
  model(
    # naïve forecast of the seasonally adjusted data
    STLNaive = decomposition_model(STL(total_rainfall), NAIVE(season_adjust)),              
    
    # auto arima forecast of the seasonally adjusted data
    STLArima = decomposition_model(STL(total_rainfall), ARIMA(season_adjust)),
    
    # Exponential Smoothing forecast of the seasonally adjusted data
    STLETS = decomposition_model(STL(total_rainfall), ETS(season_adjust ~ season("N"))),
    
    # AUTO arima
    AUTOARIMA = ARIMA(total_rainfall),    
    
    # AUTO prophet
    AUTOprophet = prophet(total_rainfall),
    
    # Auto Exponential smoothing
    AUTOETS = ETS(total_rainfall)
  )

forecast_horizon <- nrow(test_rain_week)

# Forecasting
train_rain_week_fc <- forecast(train_rain_week_fit, h = forecast_horizon)
```

```{r}
# Plotting the forecasts
c <- autoplot(train_rain_week, total_rainfall) +
  autolayer(test_rain_week, total_rainfall, series = "Test Data") +
  autolayer(train_rain_week_fc, level = NULL) +
  labs(title = "Forecast Validation for weekly total rainfall of Ang Mo Kio Station") +
  theme_minimal() 

ggplotly(c, tooltip = c("x", "y", ".model"))
```

### Testing set forcast & Accuracy Evaluation

```{r}
accuracy_metrics <- accuracy(train_rain_week_fc, test_rain_week) %>%
  arrange(.model) %>%
  select(.model, .type, RMSE, MAE, MAPE, MASE) %>%
  mutate(across(c(RMSE, MAE, MAPE, MASE), round, 2))

datatable(accuracy_metrics, 
          class= "hover",
          rownames = FALSE,
          width="100%", 
          options = list(pageLength = 10,scrollX=T))
```

#### Residual plot

```{r}
residual <- train_rain_week %>%
  model(
    # naïve forecast of the seasonally adjusted data
    STLNaive = decomposition_model(STL(total_rainfall), NAIVE(season_adjust)),              
    
    # auto arima forecast of the seasonally adjusted data
    STLArima = decomposition_model(STL(total_rainfall), ARIMA(season_adjust)),
    
    # Exponential Smoothing forecast of the seasonally adjusted data
    STLETS = decomposition_model(STL(total_rainfall), ETS(season_adjust ~ season("N"))),
    
    # AUTO arima
    AUTOARIMA = ARIMA(total_rainfall),    
    
    # AUTO prophet
    AUTOprophet = prophet(total_rainfall),
    
    # Auto Exponential smoothing
    AUTOETS = ETS(total_rainfall)
    
  )%>% 
  augment() 

a <- autoplot(residual, .innov) +
  labs(title = "Residual Plot") +
  theme_minimal() 

ggplotly(a)
```

### Refit to Full Dataset & Forecast Forward

```{r}
# Refit models to the full dataset
full_rain_week_fit <- summarised_rain_week_sstn %>%
  model(
    # naïve forecast of the seasonally adjusted data
    STLNaive = decomposition_model(STL(total_rainfall), NAIVE(season_adjust)),              
    
    # auto arima forecast of the seasonally adjusted data
    STLArima = decomposition_model(STL(total_rainfall), ARIMA(season_adjust)),
    
    # Exponential Smoothing forecast of the seasonally adjusted data
    STLETS = decomposition_model(STL(total_rainfall), ETS(season_adjust ~ season("N"))),
    
    # AUTO arima
    AUTOARIMA = ARIMA(total_rainfall),    
    
    # AUTO prophet
    AUTOprophet = prophet(total_rainfall),
    
    # Auto Exponential smoothing
    AUTOETS = ETS(total_rainfall)
  )
```

```{r}
# Plotting the forecasts along with the full dataset
future_horizon <- "10 week" # Adjust this to your forecast needs
full_rain_week_forecast <- forecast(full_rain_week_fit, h = future_horizon)
```

```{r}
e <- autoplot(full_rain_week_forecast, level = 95) +
  labs(title = "Future Forecast Plot for weekly total rainfall of Ang Mo Kio Station") +
  theme_minimal()

ggplotly(e, tooltip = c("x", "y",".model"))
```

```{r}
full_rain_week_forecast_tibble <- as_tibble(full_rain_week_forecast)

col <- full_rain_week_forecast_tibble %>% 
  mutate(year_week = paste(year(year_week), "w", 
                           sprintf("%02d", isoweek(year_week)), sep="")) %>%
  select(.model, year_week, .mean) %>% 
  rename(Forecast = .mean) %>%
  mutate(Forecast = round(Forecast, 2),
         .model = as.factor(.model),
         year_week = as.factor(year_week))

datatable(col, 
          class= "hover", 
          rownames = FALSE, 
          filter = 'top', 
          width="100%", 
          options = list(pageLength = 6, scrollX = TRUE))

```

## Section 3.3: Time Series Forecasting \[daily\]

### Min STL

```{r}
stl_formula_min <- STL(`Mean Temperature (°C)`
                       ~ trend(window = 1) +        
                         ~  season(window = 1))
```

```{r}
residual <- train_daily %>%
  model(
    # naïve forecast of the seasonally adjusted data
    STLNaive = decomposition_model(stl_formula_min, NAIVE(season_adjust)),              
    
    # auto arima forecast of the seasonally adjusted data
    STLArima = decomposition_model(stl_formula_min, ARIMA(season_adjust)),
    
    # Exponential Smoothing forecast of the seasonally adjusted data
    STLETS = decomposition_model(stl_formula_min, ETS(season_adjust ~ season("N"))),
    
    # AUTO arima
    AUTOARIMA = ARIMA(`Mean Temperature (°C)`),    
    
    # AUTO prophet
    AUTOprophet = prophet(`Mean Temperature (°C)`),
    
    # Auto Exponential smoothing
    AUTOETS = ETS(`Mean Temperature (°C)`)
  ) %>% 
  augment() 

a <- autoplot(residual, .innov) +
  theme_minimal() 

ggplotly(a)
```

### Max STL

```{r}
stl_formula_max <- STL(`Mean Temperature (°C)`
                       ~ trend(window = 365) +        
                         ~  season(window = 365))
```

```{r}
residual <- train_daily %>%
  model(
    # naïve forecast of the seasonally adjusted data
    STLNaive = decomposition_model(stl_formula_max, NAIVE(season_adjust)),              
    
    # auto arima forecast of the seasonally adjusted data
    STLArima = decomposition_model(stl_formula_max, ARIMA(season_adjust)),
    
    # Exponential Smoothing forecast of the seasonally adjusted data
    STLETS = decomposition_model(stl_formula_max, ETS(season_adjust ~ season("N"))),
    
    # AUTO arima
    AUTOARIMA = ARIMA(`Mean Temperature (°C)`),    
    
    # AUTO prophet
    AUTOprophet = prophet(`Mean Temperature (°C)`),
    
    # Auto Exponential smoothing
    AUTOETS = ETS(`Mean Temperature (°C)`)
  ) %>% 
  augment() 

a <- autoplot(residual, .innov) +
  theme_minimal() 

ggplotly(a)
```

## UI design

### Section 1

![](images/slide11.png)

### Section 2

![](images/slide12.png) ![](images/slide13.png)

### Section 3

![](images/slide14.png) ![](images/slide15.png)

## Reference

Hyndman, R.J., & Athanasopoulos, G. (2021) Forecasting: principles and practice, 3rd edition, OTexts: Melbourne, Australia. OTexts.com/fpp3.