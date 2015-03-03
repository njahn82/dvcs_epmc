require(httr)
require(plyr)
require(dplyr)
require(XML)


epmc_search <- function(query = NULL, limit = 25) {
    if (is.null(query)) 
        stop("No query provided")
    path <- paste0("search/query=", query)
    doc <- rebi_GET(path = path)
    hits <- rebi_hits(doc)
    if (hits == 0) 
        warning(sprintf("There are no citations matching your query: %s", query))
    if (hits <= 25) {
        out <- data.frame(plyr::ldply(xpathApply(doc, "//resultList//result", getChildrenStrings), rbind), 
            stringsAsFactors = FALSE)
        result <- list(hits = hits, data = tbl_df(out))
    } else {
        if (hits > limit) {
            pages <- rebi_pageing(path = path, hits = limit)
            out <- lapply(pages, rebi_request_page)
        } else {
            pages <- rebi_pageing(path = path, hits = hits)
            out <- lapply(pages, rebi_request_page)
        }
        result <- list(hits = hits, data = tbl_df(ldply(out, rbind)))
    }
    return(result)
}

rebi_GET <- function(path = NULL, ...) {
    if (is.null(path)) 
        stop("Nothing to parse")
    uri <- "http://www.ebi.ac.uk/europepmc/webservices/rest/"
    u <- paste0(uri, path)
    # call api
    req <- httr::GET(u, ...)
    # check for http status
    warn_for_status(req)
    # load xml into r
    doc <- rebi_parse(req)
    if (!exists("doc")) 
        stop("No xml to parse", call. = FALSE)
    doc
}

#' query result nodes in requested page
#'  @param x queries to be parsed

rebi_request_page <- function(x) {
    doc <- rebi_GET(x)
    out <- data.frame(plyr::ldply(xpathApply(doc, "//resultList//result", getChildrenStrings), rbind), stringsAsFactors = FALSE)
}

rebi_pageing <- function(path, hits) {
    if (all.equal((hits/25), as.integer(hits/25)) == TRUE) {
        pages <- 1:(hits/25)
    } else {
        pages <- 1:(hits/25 + 1)
    }
    sprintf("%s&page=%s", path, pages)
}

rebi_check <- function(req) {
    if (req$status_code < 400) 
        return(invisible())
    stop(http_status(x)$message, "\n", call. = FALSE)
}

rebi_parse <- function(req) {
    text <- httr::content(req, as = "text")
    if (identical(text, "")) 
        stop("Not output to parse", call. = FALSE)
    XML::xmlTreeParse(text, useInternal = TRUE)
}

rebi_hits <- function(doc) {
    as.numeric(xpathSApply(doc, "//hitCount", xmlValue))
}

### fulltext xml functions

parse_ftxt <- function(ext_id = NULL, xp = NULL) {
    if (is.null(ext_id)) 
        stop("No ext_id provided")
    path <- sprintf("%s/fullTextXML", ext_id)
    doc <- rebi_GET(path = path)
    
    xp <- sprintf("//*[contains(text(),'%s')]", xp)
    
    out <- xpathSApply(doc, xp, xmlValue)
    if(length(out) == 0) 
      out <- foo(doc)
    
    list(ext_id = ext_id, out = out)
}

foo <- function(x){
  xp <- paste0("//ref-list//*[contains(., '", dvcs, "')] | //body//*[contains(., '", dvcs, "')]")
  out <- xpathSApply(x, xp, xmlValue)
  out
}

## get github metadata (example functions from httr vignette re-used)

github_GET <- function(path, ..., pat = github_pat()) {
  auth <- github_auth(pat)
  req <- GET("https://api.github.com/", path = paste0("repos/", path), auth, ...)
  if (req$status_code < 400) {

    out <- github_parse(req)
   data <- github_nodes(out)
  
  } else { data <- data.frame() }
  list(status_code = req$status_code, data = data)
}

# github_check <- function(req) {
#   if (req$status_code < 400) return(invisible())
#   
#   message <- github_parse(req)$message
#   message
# }


github_auth <- function(pat = github_pat()) {
  authenticate(pat, "x-oauth-basic", "basic")
}

github_pat <- function() {
  Sys.getenv('GITHUB_TOKEN')
}

has_pat <- function() !identical(github_pat(), "")

github_parse <- function(req) {
  text <- content(req, as = "text")
  if (identical(text, "")) stop("Not output to parse", call. = FALSE)
  jsonlite::fromJSON(text, simplifyVector = FALSE)
}

github_nodes <- function(out) {
  tt.ls <- list(full_name = out$full_name, description = out$description, 
                language = out$language, created_at = out$created_at)
  tt.ls[sapply(tt.ls, is.null)] <- NA
  data.frame(tt.ls)
}
