**installation**
```
remotes::install_github(“pkr20/ggmanatee@main”)
install.packages(“remotes”)
library(ggmanatee)
```
**ggcats a fun package in R changed to ggmanatee, for plotting cute manatees**

here's an example of silly manatee!

```
ggplot(mtcars) +
  geom_manatee(aes(mpg, wt), manatee = "silly", size = 2)
```

![Screenshot 2024-04-22 at 10 16 08 AM](https://github.com/pkr20/ggmanatee/assets/147453190/978535d7-c84f-4b2f-b158-5af0ca49a4c6)


variety of emotions and manatees :D

```
library(ggmanatee)
grid <- expand.grid(1:5, 3:1)

df <- data.frame(x = grid[, 1],
                 y = grid[, 2],
                 image = c("grumpy", "silly", "grumpy", "silly", "grumpy", "manatee", "silly", "bongo", "cute", "happy", "sleepy", "relaxed", "cry", "stars", "chill"))
                           
library(ggplot2)
ggplot(df) +
 geom_manatee(aes(x, y, manatee = image), size = 5) +
    xlim(c(0.25, 5.5)) + 
    ylim(c(0.25, 3.5))
```


<img width="669" alt="Screenshot 2024-04-22 at 10 32 28 AM" src="https://github.com/pkr20/ggmanatee/assets/147453190/63dbc876-45cf-40ba-b1f7-e87183117aad">
