context("test-generate_plots.R")

#load SIR model for testing
modelpath = system.file("modelexamples", package = "modelbuilder")
mbmodel <- readRDS(paste0(modelpath,'/SIR_model.Rds'))

#set settings for model to run
modelsettings = list( S = 1000, I = 1, R = 0, b = 2e-3, g = 1, tstart  = 0, tfinal = 100, dt = 0.1)

modelsettings$nreps = 1
modelsettings$rngseed = 123
modelsettings$plotscale = 'lin'
modelsettings$modeltype = "ode"
modelsettings$scanparam = 0

simresult <- analyze_model(modelsettings = modelsettings, mbmodel = mbmodel)


test_that("generate_ggplot returns a plot without specifying anything",
{
  expect_is( modelbuilder::generate_ggplot(simresult), "ggplot" )
})

test_that("generate_ggplot returns a plot when choosing scatterplot or boxplot",
{
            simresult[[1]]$plottype = "Scatterplot"
            expect_is( modelbuilder::generate_ggplot(simresult), "ggplot" )
            simresult[[1]]$plottype = "Boxplot"
            expect_is( modelbuilder::generate_ggplot(simresult), "ggplot" )
})
