# functions stored in zzz.R

source(file = "R/zzz.R")

# base urls to hosting services
dvcs <- c("code.google.com", "github.com", "sourceforge.net", "bitbucket.org")
# make queries including reference section
dvcs.query <- paste(dvcs, "%20OR%20REF:", dvcs, sep="")
# queried through epmc
tt <- lapply(dvcs.query, epmc_search, limit = 10000)
tt.df <- dplyr::bind_rows(lapply(tt, "[[", "data"))
hits <- sapply(tt, "[[", "hits")
tt.df$dvcs <- rep(dvcs, times = hits)
write.csv(tt.df,"data/dvcs_epmc_md.csv", row.names = FALSE)

# fetch dvcs repos from epmc oa fulltexts

my.df <- read.csv("data/dvcs_epmc_md.csv", header = TRUE , sep = ",")
my.oa <- my.df[!is.na(my.df$pmcid) & my.df$isOpenAccess == "Y",]
# exclude PMC4317665 because it is missing in PMC OA corpus

pmcid_dvcs <- llply(my.oa$pmcid, parse_ftxt, dvcs)
dvcs_urls <- unlist(sapply(pmcid_dvcs, "[[", "out"))

# extract urls-strings
u <- unique(stringr::str_extract(dvcs_urls, "http[[:graph:]]*"))
u <- u[!is.na(u)]
# minimum three slashes
tt <- llply(urls, httr::parse_url, .inform = T)
urls.mat <- do.call("rbind", tt)
# only host name and path
urls.mat <- urls.mat[,c("hostname", "path")]
write.csv(urls.mat, "data/urls_parsed.csv")
