## Exploring how to retrieve links to software repositories from Europe PMC

Hosting services examined:

- code.google.com
- github.com
- sourceforge.net
- bitbucket.org

R functions used are stored in folder `R`, execution script is `script.r`

## Approach

1. Search EPMC for base urls of the hosting services including reference section:

```{r}
# base urls to hosting services
dvcs <- c("code.google.com", "github.com", "sourceforge.net", "bitbucket.org")
# make queries including reference section
dvcs.query <- paste(dvcs, "%20OR%20REF:", dvcs, sep="")
# queried through epmc
tt <- lapply(dvcs.query, epmc_search, limit = 10000)
```

Result stored in `data/dvcs_epmc_md.csv`

2. Subset for Open Access full texts

3. Query each full text and apply xpath expressions to retrieve urls

4. Extract http strings

5. parse urls with ```httr::parse_urls```

Result is stored in ```data/urls_parsed.csv```

Next steps:

- query dvcs-Apis for title and exact paths
- query EPMC search again to retrieve counts




Besides providing a list of links to software repositories, which are mentioned in the scientific literature, for the open source software [lagotto](https://github.com/articlemetrics/lagotto), the aim isto post pictures of Alfons, the Bielefeld/Hannover-based Lagotto puppy.

![Lagotto Alfons](https://libcloud.ub.uni-bielefeld.de/index.php/apps/files_sharing/publicpreview?file=%2F%2FAlfons%20Couch.jpg&x=1718&y=948&a=true&t=4ba52645e3a48a52bd268b2f4b1a2e8f&scalingup=0&forceIcon=0)

License: CC0 



