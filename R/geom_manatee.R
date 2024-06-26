##' key drawing function
##'
##'
##' @name draw_key
##' @param data A single row data frame containing the scaled aesthetics to display in this key
##' @param params A list of additional parameters supplied to the geom.
##' @param size Width and height of key in mm
##' @return A grid grob
NULL


ggname <- getFromNamespace("ggname", "ggplot2")

##' @rdname draw_key
##' @importFrom grid rectGrob
##' @importFrom grid pointsGrob
##' @importFrom grid gpar
##' @importFrom grDevices as.raster
##' @export
draw_key_manatee <- function(data, params, size) {

  filename <- system.file(paste0(data$manatee, ".png"), package = "ggmanatee")
  img <- as.raster(png::readPNG(filename))
  aspect <- dim(img)[1]/dim(img)[2]
  # rasterGrob
  grid::rasterGrob(image = img,
                   width = ggplot2::unit(data$size / size, 'snpc'),
                   height = ggplot2::unit(data$size / size * aspect, 'snpc'))
}


##' geom layer adding manatees
##'
##'
##' @title geom_manatee
##' @param mapping aes mapping
##' @param data data
##' @param stat stat
##' @param position position
##' @param inherit.aes logical, whether inherit aes from ggplot()
##' @param na.rm logical, whether remove NA values
##' @param by one of 'width' or 'height'
##' @param nudge_x horizontal adjustment to nudge manatees
##' @param ... additional parameters
##' @return geom layer
##' @importFrom ggplot2 layer
##' @export
##' @examples
##' library("ggplot2")
##' ggplot(mtcars) +
##' geom_manatee(aes(mpg, wt), manatee = "manatee", size = 5)
##'
##' set.seed(1)
##' df <- data.frame(x = rnorm(10),
##'                  y = rnorm(10),
##'                  image = sample(c("manatee",
##'                                   "pusheen",
##'                                   "colonel",
##'                                   "venus",
##'                                   "toast"),
##'                                  size = 10, replace = TRUE))
##'  ggplot(df) +
##' geom_manatee(aes(x, y, manatee = image), size = 5)
##'
geom_manatee <- function(mapping = NULL, data = NULL, stat = "identity",
                     position = "identity", inherit.aes = TRUE,
                     na.rm = FALSE, by = "width", nudge_x = 0, ...) {

  by <- match.arg(by, c("width", "height"))

  layer(
    data = data,
    mapping = mapping,
    geom = Geommanatee,
    stat = stat,
    position = position,
    show.legend = NA,
    inherit.aes = inherit.aes,
    params = list(
      na.rm = na.rm,
      by = by,
      nudge_x = nudge_x,
      ##angle = angle,
      ...),
    check.aes = FALSE
  )
}


##' @importFrom ggplot2 ggproto
##' @importFrom ggplot2 Geom
##' @importFrom ggplot2 aes
##' @importFrom ggplot2 draw_key_blank
##' @importFrom grid gTree
##' @importFrom grid gList
Geommanatee <- ggplot2::ggproto("Geommanatee", ggplot2::Geom,
                     setup_data = function(data, params) {
                       if (is.null(data$subset))
                         return(data)
                       data[which(data$subset),]
                     },

                     default_aes = ggplot2::aes(manatee = "nyanmanatee", size = 1,
                                       colour = NULL, angle = 0, alpha = 1),

                     draw_panel = function(data, panel_params, coord, by, na.rm=FALSE,
                                           .fun = NULL, height, image_fun = NULL,
                                           hjust = 0.5, nudge_x = 0, nudge_y = 0, asp = 1) {
                       data$x <- data$x + nudge_x
                       data$y <- data$y + nudge_y
                       data <- coord$transform(data, panel_params)

                       if (!is.null(.fun) && is.function(.fun)) {
                         data$ca <- .fun(data$manatee)
                       }
                       if (is.null(data$manatee)) return(NULL)

                       groups <- split(data, factor(data$manatee))
                       imgs <- names(groups)
                       grobs <- lapply(seq_along(groups), function(i) {
                         d <- groups[[i]]
                         if (is.na(imgs[i])) return(zeroGrob())

                         imageGrob(d$x, d$y, d$size/5, imgs[i], by, hjust,
                                   d$colour, d$alpha, image_fun, d$angle, asp)
                       })
                       grobs <- do.call("c", grobs)
                       class(grobs) <- "gList"

                       ggplot2:::ggname("geom_manatee",
                              gTree(children = grobs, cl = "fixasp_raster"))
                     },
                     non_missing_aes = c("size", "manatee"),
                     required_aes = c("x", "y"),
                     draw_key = draw_key_manatee ## draw_key_blank ## need to write the `` function.
)



##' @importFrom grid rasterGrob
##' @importFrom grid viewport
##' @importFrom grDevices rgb
##' @importFrom grDevices col2rgb
##' @importFrom tools file_ext
imageGrob <- function(x, y, size, img, by, hjust, colour, alpha, image_fun, angle, asp = 1) {
  if (!methods::is(img, "magick-image")) {
      filename <- system.file(paste0(img, ".png"), package = "ggmanatee")
      img <- magick::image_read(filename)

    asp <- getAR2(img)/asp
  }

  unit <- "native"
  if (any(size == Inf)) {
    x <- 0.5
    y <- 0.5
    width <- 1
    height <- 1
    unit <- "npc"
  } else if (by == "width") {
    width <- size/5
    height <- (size / asp)/5
  } else {
    width <- (size * asp)/5
    height <- size/5
  }

  if (hjust == 0 || hjust == "left") {
    x <- x + width/2
  } else if (hjust == 1 || hjust == "right") {
    x <- x - width/2
  }

  if (!is.null(image_fun)) {
    img <- image_fun(img)
  }


  if (is.null(colour)) {
    grobs <- list()
    grobs[[1]] <- rasterGrob(x = x,
                             y = y,
                             image = img,
                             default.units = unit,
                             height = height,
                             width = width,
                             interpolate = FALSE)
  } else {
    cimg <- lapply(seq_along(colour), function(i) {
      color_image(img, NULL, alpha[i])
    })

    grobs <- lapply(seq_along(x), function(i) {
      img <- cimg[[i]]
      if (angle[i] != 0) {
        img <- magick::image_rotate(img, angle[i])
        img <- magick::image_transparent(img, "white")
      }
      rasterGrob(x = x[i],
                 y = y[i],
                 image = img,
                 default.units = unit,
                 height = height,
                 width = width,
                 interpolate = FALSE
                 ## gp = gpar(rot = angle[i])
                 ## vp = viewport(angle=angle[i])
      )
    })
  }
  return(grobs)
}



getAR2 <- function(magick_image) {
  info <- magick::image_info(magick_image)
  info$width/info$height
}


compute_just <- getFromNamespace("compute_just", "ggplot2")

color_image <- function(img, color, alpha = NULL) {
  if (is.null(color))
    return(img)

  if (length(color) > 1) {
    stop("color should be a vector of length 1")
  }

  bitmap <- img[[1]]
  col <- col2rgb(color)
  bitmap[1, , ] <- as.raw(col[1])
  bitmap[2, , ] <- as.raw(col[2])
  bitmap[3, , ] <- as.raw(col[3])

  if (!is.null(alpha) && alpha != 1)
    bitmap[4, , ] <- as.raw(as.integer(bitmap[4, , ]) * alpha)

  magick::image_read(bitmap)
}
