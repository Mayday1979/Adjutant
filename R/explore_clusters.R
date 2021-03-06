#' Nearest clicked cluster
#' @export
#' @param corpus a document corpus
#' @param e co-ordinates from mouse click
clickedClusterSum<-function(corpus =NULL, e = NULL){
  
  if(!is.null(e)){
    selPts<-nearPoints(corpus, e, threshold=10,xvar = "tsneComp1", yvar = "tsneComp2")
    
    if(nrow(selPts)>0){
      #get the most common cluster in hovPts
      tmp<-selPts %>%
        group_by(tsneClusterNames)%>%
        dplyr::count()%>%
        ungroup()%>%
        top_n(1,-n)

      return(tmp)
    }else{
      return(NULL)
    }
  }else{
    return(NULL)
  }
}


#' Print a summary statement for topic clusters
#' @export
#' @param corpus a document corpus
#' @param clustSelected name of a cluster
clusterSummaryText<-function(corpus = NULL,clustSelected=NULL){
  
  tmp <- corpus %>%
    filter(tsneClusterNames == clustSelected)
  
  if(!is.null(tmp)){
    hovMsg<-sprintf("<h4><em> %s</em></h4>Cluster <strong>%s</strong> has <strong>%d</strong> members<br>",clustSelected,clustSelected,nrow(tmp))
  }
  
  return(hovMsg)
}


#' Top Papers for a cluster
#' @export
#' @param corpus a document corpus
#' @param selectedCluster a name of cluster
getTopPapers<-function(corpus=NULL,selectedCluster=NULL){
  
  
  topPapers<-""
  topRef<-corpus %>%
    filter(tsneClusterNames == selectedCluster) %>%
    mutate(pmcCitationCount = as.numeric(as.character(pmcCitationCount)))%>% 
    filter(!is.na(pmcCitationCount))
    
    
    if(nrow(topRef)>0){
      topRef<-topRef%>%
        arrange(-pmcCitationCount)%>%
        ungroup()%>%
        top_n(5,pmcCitationCount)
      
      #really only return 5 if there are alot of ties
      if(nrow(topRef)>5){
        topRef<-topRef[1:5,]
      }
      
      #summarize this all into a word thing to output
      tmp2<-select(topRef,"PMID","YearPub","Journal","Authors","Title")
      topPaperText<-apply(tmp2,1,function(x){
        pmid = x[1]
        year = x[2]
        journal = x[3]
        authors =  paste(strsplit(as.character(x[4]),";")[[1]][1],"<em>et.al</em>")
        title = x[5]
        
        sprintf("%s (<strong>%s</strong>) <em>%s</em> <strong>%s</strong> PMID:<a target='_blank' href='https://www.ncbi.nlm.nih.gov/pubmed/%s'>%s</a>",authors,year,title,journal,pmid,pmid)
      })
      
      topPapers<-paste0(topPaperText,collapse="<br><br>")
      topPapers<-sprintf("<h4><em> Top Papers: </em></h4> %s",topPapers)
    }
  
  return(topPapers)
}


#' Naming clusters
#'
#' @param clustPMID  PMID values for documents within the cluster
#' @param topNVal # of top terms used to name cluster
#' @param clustValue cluster identified, mainly used to check it unclustered 
#' @param tidyCorpus tidytext document corpus
#'
#' @import dplyr
#' @return topWord : a string of top two terms for a given cluster
#' @export
#'
# getTopTerms<-function(clustPMID=NULL,topNVal=1,clustValue = NA,tidyCorpus = NULL){
#   
#   clustValue<-clustValue[1]
#   
#   if(clustValue == 0)
#     return("Not-Clustered")
#   
#   topWord<-tidyCorpus %>%
#     filter(PMID %in% clustPMID) %>%
#     ungroup() %>%
#     group_by(wordStemmed) %>%
#     dplyr::count() %>%
#     ungroup()%>%
#     arrange(-nn) %>%
#     top_n(topNVal)
#   
#   # return character and collapse top terms (useful in even of a tie)
#   topWord<-paste0(topWord$wordStemmed,collapse = "-")
#   return(topWord)
# }

#top terms in each cluster
#' Get Top Terms in Each Cluster
#' @export
#' @param corpus a document corpus
#' @param corpusTidy a tidy text version of the corpus
#' @param selectedCluster a name of a cluster
topClustTerms<-function(corpus = NULL,corpusTidy=NULL,selectedCluster = NULL){
  

  pmids<-corpus %>% filter(tsneClusterNames == selectedCluster)%>% select(PMID)
    
    df<-corpusTidy %>%
      filter(PMID %in% pmids$PMID) %>% 
      group_by(wordStemmed) %>%
      dplyr::count()%>%
      ungroup()%>%
      mutate(freq = nn/nrow(pmids)) %>%
      arrange(-freq) %>% 
      top_n(10)
    
    topTerms<-paste(as.character(df$wordStemmed),collapse =",")
    return(sprintf("<h4><em> Top Terms </em><br></h4> %s </br>",topTerms))
}