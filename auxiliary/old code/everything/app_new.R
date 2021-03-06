#This is the Shiny App for the main menu of the modelbuilder package

#this function is the server part of the app
server <- function(input, output, session) {

  stopping <- FALSE

  #code to run build model functionality needs to go here
  observeEvent(input$buildmodel, {
  })

  #make the UI for the model, saves those into the output elements
  generate_shinyinput(model(), output)


  output$analyzemodel <- renderUI({
      fluidPage(
          #section to add buttons
          fluidRow(column(
              12,
              actionButton("submitBtn", "Run Simulation", class = "submitbutton")
          ),
          align = "center"),
          #end section to add buttons
          tags$hr(),
          ################################
          #Split screen with input on left, output on right
          fluidRow(
              #all the inputs in here
              column(
                  6,
                  h2('Simulation Settings'),
                  column(
                      6,
                      uiOutput("vars"),
                      uiOutput("time")
                  ),
                  column(
                      6,
                      uiOutput("pars"),
                      uiOutput("other")

                  )),
              #end sidebar column for inputs

              #all the outcomes here
              column(
                  6,
                  #################################
                  #Start with results on top
                  h2('Simulation Results'),
                  plotOutput(outputId = "plot", height = "500px"),
                  # PLaceholder for results of type text
                  htmlOutput(outputId = "text"),
                  tags$hr()
              ) #end main panel column with outcomes
          ), #end layout with side and main panel

          #################################
          #Instructions section at bottom as tabs
          h2('Instructions')
          #use external function to generate all tabs with instruction content
          #browser(),
          #do.call(tabsetPanel, generate_documentation() ),
      ) #end fluidpage for analyze tab
    }) # End renderUI for analyze tab


  observeEvent(input$submitBtn, {
      result <- analyze_model(modeltype = input$modeltype,
                    rngseed = input$rngseed, nreps = input$nreps,
                    plotscale = input$plotscale, input = input, model = model() )

      #create plot from results
      output$plot  <- renderPlot({
          generate_plots(result)
      }, width = 'auto', height = 'auto')

      #create text from results
      output$text <- renderText({
          generate_text(result)     #create text for display with a non-reactive function
      })

      }) #end observe-event for analyze model submit button

  observeEvent(input$Exit, {
      stopping <<- TRUE
      stopApp('Exit')
  })

  model <- reactive({
    stopping <<- TRUE
    inFile <- input$currentmodel
    if (is.null(inFile)) return(NULL)
    # loadRData() below was suggesed on Stack Overflow 8/22/14 by user ricardo.
    # The code was provided for general use in answer to another user's question
    # about loading data into R. The original source for the code can be found
    # here: https://stackoverflow.com/questions/5577221/how-can-i-load-an-object-into-a-variable-name-that-i-specify-from-an-r-data-file
    loadRData <- function(filename) {
      load(filename)
      get(ls()[ls() != "filename"])
    }
    d <- loadRData(inFile$datapath)
  })

  output$exportode <- downloadHandler(
    filename = function() {
      paste0("simulate_",gsub(" ","_",model()$title),"_ode.R")
    },
    content = function(file) {
      stopifnot(!is.null(model()))
      generate_ode(model = model(), location = file)
    },
    contentType = "text/plain"
  )

  output$exportstochastic <- downloadHandler(
    filename = function() {
      paste0(gsub(" ","_",model$title),"_stochastic.R")
    },
    content = function(file) {
      stopifnot(!is.null(model()))
      convert_to_rxode(model = model(), location = file)
    },
    contentType = "text/plain"
  )

  output$exportdiscrete <- downloadHandler(
    filename = function() {
      paste0("simulate_",gsub(" ","_",model()$title),"_discrete.R")
    },
    content = function(file) {
      stopifnot(!is.null(model()))
      generate_discrete(model = model(), location = file)
    },
    contentType = "text/plain"
  )

  output$rxode <- downloadHandler(
      filename = function() {
          paste0(gsub(" ","_",model$title),"_rxode.R")
      },
      content = function(file) {
          stopifnot(!is.null(model()))
          convert_to_rxode(model = model(), location = file)
      },
      contentType = "text/plain"
  )

  session$onSessionEnded(function() {
    if (!stopping) {
      stopApp('Exit')
    }
  })

}


#This is the UI for the Main Menu of modelbuilder
ui <- fluidPage(
  includeCSS("../media/modelbuilder.css"),
  #add header and title
  div( includeHTML("../media/header.html"), align = "center"),
  p(paste('This is modelbuilder version ',utils::packageVersion("modelbuilder"),' last updated ', utils::packageDescription('modelbuilder')$Date,sep=''), class='infotext'),

  navbarPage("modelbuilder",
              tabPanel("Main",
                       fluidRow(
                           column(12,
                                  fileInput("currentmodel", label = "Load a Model", accept = ".Rdata", buttonLabel = "Load Model", placeholder = "No model selected"),
                                  align = 'center' )
                       ),

                       fluidRow(
                           column(12,
                                  verbatimTextOutput("modeltitle"),
                                  align = 'center'),
                           class = "mainmenurow"
                       ),
                       p('Get the R code for the currently loaded model', class='mainsectionheader'),
                       fluidRow(
                           column(3,
                                  downloadButton("exportode", "Export ODE code")
                           ),
                           column(3,
                                  downloadButton("exportstochastic", "Export stochastic code")
                           ),
                           column(3,
                                  downloadButton("exportdiscrete", "Export discrete-time code")
                           ),
                           column(3,
                                  downloadButton("exportrxode", "Export RxODE code")
                           ),
                           class = "mainmenurow"
                       ), #close fluidRow structure for input

                       p('Import or Export SBML models', class='mainsectionheader'),
                       fluidRow(
                           column(6,
                                  actionButton("importsbml", "Import a SBML model", class="mainbutton")
                           ),
                           column(6,
                                  actionButton("exportsbml", "Export to SMBL model", class="mainbutton")
                           ),
                           class = "mainmenurow"
                       ) #close fluidRow structure for input
               ), #close "Main" tab
              tabPanel("Build",
                       fluidRow(
                           column(12,
                                  actionButton("buildmodel", "Build a new model", class="mainbutton")
                           ),
                           class = "mainmenurow"
                       )

               ), #close "Build" tab
              tabPanel("Analyze",
                       fluidRow(
                           column(12,
                                  #actionButton("analyzemodel", "Analyze current model", class = "mainbutton")
                                  uiOutput('analyzemodel')
                           ),
                           class = "mainmenurow"
                       ) #close fluidRow structure for input
              ) #close "Analyze" tab
  ),

  p('Have fun building and analyzing models!', class='maintext'),
  div(includeHTML("../media/footer.html"), align="center", style="font-size:small") #footer
) #end fluidpage

shinyApp(ui = ui, server = server)
