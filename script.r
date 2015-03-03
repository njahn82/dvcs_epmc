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

# check github for metadata on software repos

urls.df <- as.data.frame(urls.mat)
urls.github <- urls.df[urls.df$hostname == "github.com",]

tmp <- stringr::str_split_fixed(as.character(urls.github$path), "/", 2)
tmp <- cbind(tmp, stringr::str_split_fixed(tmp[,2], "/", 2))

user <- tmp[,1]
repo <- tmp[,3]

path <- paste(user, repo, sep = "/")

tt <- lapply(path, github_GET)
tt.df <-  dplyr::bind_rows(lapply(tt, "[[", "data"))

write.csv(tt.df, "data/github_parsed.csv")

## compare with lagotto list

gh_ls <- read.csv("data/github_repos.csv", header = T, sep =",")
pmc_ls <- read.csv("data/github_parsed.csv", header = T, sep =",")
pmc_ls$url <- paste0("https://github.com/", pmc_ls$full_name)
pmc_ls <- pmc_ls[!duplicated(pmc_ls$url),]
gh_new <- pmc_ls[!pmc_ls$url %in% gh_ls$url,]

gh_new$create_date <- as.Date(gh_new$created_at, format = "%Y-%m-%d")
gh_ls$create_date <- as.Date(gh_ls$create_date, format = "%Y-%m-%d")
gh_new$title <- gh_new$description

gh.to.bind <- gh_new[,c("url", "create_date", "title")]
gh <- rbind(gh_ls, gh.to.bind)
write.csv(gh, "data/github_repos.csv", row.names = F)

