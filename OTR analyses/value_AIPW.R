#------------------------------------------------------------------------------#
# AIPW estimator for value of a fixed binary tx regime
#
# ASSUMPTIONS
#   tx is binary coded as {0,1}
#
# INPUTS
#    moOR : modeling object specifying outcome regression
#    moPS : modeling object specifying propensity score regression
#    data : data.frame containing baseline covariates and tx
#           *** tx must be coded 0/1 ***
#       y : outcome of interest
#  txName : tx column in data (tx must be coded as 0/1)
#  regime : 0/1 vector containing recommended tx
#
# RETURNS
#  a list containing
#     fitOR : value object returned by outcome regression
#     fitPS : value object returned by propensity score regression
#        EY : sample average outcome for each tx received
#  valueHat : estimated value
#------------------------------------------------------------------------------#
value_AIPW <- function(moOR, moPS, data, y, txName, regime) {

  #### Propensity Score

  fitPS <- modelObj::fit(object = moPS, data = data, response = data[,txName])

  # estimated propensity score
  p1 <- modelObj::predict(object = fitPS, newdata = data)
  if (is.matrix(x = p1)) p1 <- p1[, ncol(x = p1), drop = TRUE]

  #### Outcome Regression

  fitOR <- modelObj::fit(object = moOR, data = data, response = y)
  
  # store tx variable
  A <- data[,txName]

  # estimated Q-function when all A=d
  data[,txName] <- regime
  Qd <- drop(x = modelObj::predict(object = fitOR, newdata = data))

  #### Value

  Cd <- regime == A
  pid <- p1*{regime == 1L} + {1.0-p1}*{regime == 0L}

  value <- Cd * y / pid - {Cd - pid} / pid * Qd

  EY <- array(data = 0.0, dim = 2L, dimnames = list(c("0","1")))
  EY[1L] <- mean(x = value*{A == 0L})
  EY[2L] <- mean(x = value*{A == 1L})

  value <- sum(EY)

  return( list(   "fitOR" = fitOR,
                  "fitPS" = fitPS,
                     "EY" = EY,
               "valueHat" = value) )
               
}
