# The optimal treatment regime with the value search estimator and a linear
# decision rule is estimated. We start by defining a function that performs the
# OTR estimation for a single imputed data set and outcome. This enables us to
# further easily use parallel computing.
OTR_estimator = function(outcome,
                         main_covariates,
                         cont_covariates,
                         treatment,
                         data,
                         seed,
                         pop_size = 1000L,
                         wait_generations = 10L, 
                         starting_values = "Q") {
  # Set seed for reproducibility and possibility of running the stochastic
  # genetic algorithm multiple times. By using the local_seed() function, the
  # seed is set only locally. This only affects the code within the scope, i.e.,
  # the current function body.
  withr::local_seed(seed)
  # Formula for the v- and c-functions are constructed from the character
  # vectors in main_covariates and cont_covariates.
  main_formula = as.formula(paste("~", paste(main_covariates, collapse = " + ")))
  cont_formula = as.formula(paste("~", paste(cont_covariates, collapse = " + ")))
  # Number of parameters for the optimal treatment regime function.
  n_para = ncol(model.matrix(cont_formula, data = data))
  # The DynTxRegime package uses function genoud in package rgenoud to estimate
  # the optimal treatment regime. rgenoud requires some settings such as the
  # domain to search for eta, the starting values, and the population size for
  # the algorithm.
  Domains <- matrix(rep(c(-1.0, 1.0), n_para),
                    nrow = n_para,
                    ncol = 2,
                    byrow = T)
  
  # The population size is by far the most important parameter in the genetic 
  # algorithm. A population size of 1000 has been used in the code accompanying
  # the book for DynTxReg.
  pop.size <- pop_size
  # For this method AIPW estimator, we need a propensity score model. Since
  # treatment is randomized, no covariates are included in this propensity
  # score model.
  Propen1d <- modelObj::buildModelObj(
    model = ~ 1,
    solver.method = 'glm',
    solver.args = list(family = 'binomial'),
    predict.method = 'predict.glm',
    predict.args = list(type = 'response')
  )
  
  # The outcome regression part of the AIPW estimator is specified in two parts.
  # First, the v-function contains the main effects. Second, the c-function
  # contains interaction effects.
  
  # Build the v-function.
  q1d_Main <- modelObj::buildModelObj(
    model = main_formula,
    solver.method = 'lm',
    predict.method = 'predict.lm'
  )
  # Build the c-function. 
  q1d_Cont <- modelObj::buildModelObj(
    model = cont_formula,
    solver.method = 'lm',
    predict.method = 'predict.lm'
  )
  # Three options are provided for determining the starting values.
  if (starting_values == "Q") {
    # Staring values are based on the estimated regime parameters from Q-learning.
    q_estimates = coef(DynTxRegime::qLearn(
      moMain = q1d_Main,
      moCont = q1d_Cont,
      data = as.data.frame(data),
      response = data$change_score,
      txName = "group_int",
      verbose = TRUE
    ))
    q_estimates = q_estimates$outcome$Combined[12:17]
    starting.values = q_estimates / sqrt(sum(q_estimates * q_estimates))
  }
  else if (starting_values == "zero") {
    # Starting values correspond to the zero vector.
    starting.values = rep(0, n_para)
  }
  else if (starting_values == "random") {
    # Random starting values.
    starting.values = runif(n_para, min = -1, max = 1)
  }
  
  # We need to specify the form of the regime d, i.e., we search within this
  # restricted subset of D. We do not give formal arguments in the function
  # definition because the number of formal arguments depends on the outcome of
  # the variable selection.
  regime1d <- function(...) {
    # Put the arguments given to this function when it is invoked in a list. All
    # arguments are treatment regime parameters, expect the last one. The last
    # argument is the data set.
    args = as.list(environment())
    # Number of treatment regime parameters
    p = length(args) - 1
    eta = unlist(args[1:p])
    data = args[[p + 1]]
    # Computed model matrix based on the formula for the contrast function. The
    # model.matrix() function also automatically computed the required dummy
    # variables if categorical variables are present in cont_formula. An
    # intercept is also automatically included.
    model_matrix = model.matrix(cont_formula, data)
    # Computed predicted optimal treatment allocation.
    tmp <- as.matrix(model_matrix) %*% eta > 0.0
    return(as.integer(x = tmp))
  }
  # Define parameter names for the treatment regime parameters.
  eta_vector = colnames(model.matrix(cont_formula, data = data))
  # We define the formal argument for the treatment regime function, regime1d(),
  # in a post hoc fashion. This is not good coding practice but allows this
  # function to be used very flexibly.
  a_list_formals = as.list(starting.values)
  a_list_formals = append(a_list_formals, NA)
  names(a_list_formals) = c(eta_vector, "data")
  formals(regime1d) = a_list_formals
  # Estimate optimal treatment regime.
  AIPW1d <- DynTxRegime::optimalSeq(
    moPropen = Propen1d,
    moMain = q1d_Main,
    moCont = q1d_Cont,
    data = as.data.frame(data),
    response = outcome,
    txName = "group_int",
    regimes = regime1d,
    Domains = Domains,
    pop.size = pop.size,
    wait.generations = wait_generations,
    starting.values = starting.values,
    solution.tolerance = 0.00001,
    gradient.check = FALSE,
    verbose = TRUE
  )
  return(AIPW1d)
}