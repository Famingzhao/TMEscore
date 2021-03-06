





#' pcr_2deltaCt
#'
#' @param data Sample is in the first column, next is gene
#' @param Sample name of Sample
#' @param ref_gene genes as reference
#' @param Dup.ID default is c("D1", "D2", "D3"), so the same sample should be stay together
#'
#' @return
#' @export
#'
#' @examples
pcr_2deltaCt<-function(data, Sample = "Sample", ref_gene = "ACTB", Dup.ID = c("D1", "D2", "D3"), path = "0-QC-data"){
  
  
  #' 参考链接：https://zouhua.top/archives/3db8e2e5.html
  #' 参考链接：https://www.biolab.wang/r/r_for_qpcr
  #' 
  if(!file.exists(path)) dir.create(path)
  abspath<-paste(getwd(),"/",path,"/",sep ="" )
  ##############################
  
  data<-as.data.frame(data)
  
  message(paste0("Number of NA: ", sum(is.na(data))))
  
  dat<-reshape2:: melt(data, variable_name = "gene")
  
  head(dat)
  colnames(dat)[2]<-"gene"
  colnames(dat)[3]<-"Cq"
  colnames(dat)[which(colnames(dat)==Sample)]<-"Sample"
  
  # 添加一列，记录重复的ID
  dat$Dup.ID <- Dup.ID
  ###############################
  
  # 如果Cq一列不是数值类型，要当心，如果这一列是factor而直接转为数值的话，会出错
  if(class(dat$Cq) != "numeric"){
    dat$Cq <- as.numeric(as.character(dat$Cq))
  }
  
  # 对于没有数值的孔，将它设置为50
  if(sum(is.na(dat$Cq)) > 0){
    dat$Cq[is.na(dat$Cq)] <- 50
  }
  
  # 对数据进行变形，使得同一个鼠的同一个基因的三个孔的数据在同一行，方便处理
  Dat <- data.frame(cast(dat, gene + Sample ~Dup.ID, value="Cq"))
  head(Dat)
  #######################
  
  
  # 先看看数据质量如何，是否有的3个重复孔之中存在异常值，使用dixon.outliers函数，自己看看相关说明
  Dat$OL <- apply(Dat[ , c("D1", "D2", "D3")], 1, function(x){
    if(sd(x) == 0) {
      return("")
    } else {
      return(paste(dixon.outliers(x)$outliers, collapse=","))
    }
  })
  
  Dat[Dat$OL != "", ]  #这样查看具有异常值的列
  
  # 考虑到异常值的情况下来求Ct的平均值
  # 使用dixon.outliers函数来查看三个重复中的异常值
  # 如果存在异常值，并且异常值与其它两个值的平均值差距大于0.9，那么就把异常值去掉之后再求平均值
  Dat$Ct <- apply(Dat[ , c("D1", "D2", "D3")], 1, mean)
  
  # 如果存在异常值，那么需要考虑有异常值的情况
  if(sum(Dat$OL != "") > 0){
    Dat[Dat$OL != "", ]$Ct <- apply(Dat[Dat$OL != "", c("D1", "D2", "D3")], 1, function(x){
      Ou <- as.numeric(dixon.outliers(x)$outliers)   # 异常值
      # print(Ou)
      Su <- dixon.outliers(x)$subset     # 除去异常值之后剩下的数值
      # print(Su)
      if(mean(Su)==50){
        return(Ou)  
      }else if(abs(Ou - mean(Su)) > 0.9){
        return(mean(Su))                           # 如果异常值与非异常值的平均数之差大于0.5，则去掉异常值
      } else {
        return(mean(x))                            # 否则还是使用全部3个数的平均值
      }
    })
  }
  write.csv(Dat,file = paste0(abspath, "1-raw-data-Ct.csv"))
  
  Dat[Dat$OL != "", ]  #这样查看具有异常值的列
  #####################################
  
  ref_gene<-ref_gene[ref_gene%in%Dat$gene]
  
  if(length(ref_gene)==1){
    # ACTB的数据单独拿出来
    Dat1 <- Dat[Dat$gene == ref_gene, c("Sample", "Ct")]
    names(Dat1) <- c("Sample", "Cr")   # r 代表 reference gene
  }else if(length(ref_gene)>1){
    
    Dat1 <- Dat[Dat$gene%in%ref_gene, c("Sample", "gene", "Ct")]
    Dat1<-reshape2:: dcast(data = Dat1, Sample~gene)
    Dat1$Cr<-rowMeans(Dat1[,2:ncol(Dat1)])
    Dat1<-Dat1[,c("Sample", "Cr")]
  }else if(length(ref_gene)==0){
    stop("Reference gene is not avlailable")
  }

  # 和其它两个目标基因的数据merge在一起
  DAT <- merge(Dat[Dat$gene != ref_gene, c("gene", "Sample", "Ct")], Dat1, by="Sample", all.x=TRUE)
  
  head(DAT)
  # 求ΔCt，用基因的Ct减去参照基因的Ct
  DAT$dCt <- DAT$Ct -DAT$Cr
  
  # 接下来秋ΔΔCt， 这个针对每个基因单独求，因此先求出各个基因的平均ΔCt
  DAT1 <- ddply(DAT, .(gene), summarize, Cm = mean(dCt))   # Cm表示dCt的平均值
  
  # 再把各个基因对应的最大的ΔCt与各个样本的ΔCt对应merge在一起
  DAT <- merge(DAT, DAT1, by="gene", all.x=TRUE)
  head(DAT)
  
  # 求ΔΔCt
  DAT$ddCt <- DAT$dCt - DAT$Cm   #
  # 通过ΔΔCt来求每个样本对应的相对表达量
  DAT$Fc <- 2^(-DAT$ddCt)   # Fc表示Fold Change，这里是相对表达量
  head(DAT)
  write.csv(DAT,file = paste0(abspath, "2-delta-Ct.csv"))
  ##################################

  dat<-DAT[,c("Sample","gene","Fc")]
  head(dat)
  
  dat<-reshape2:: dcast(data = dat, gene~Sample)
  write.csv(dat,file = paste0(abspath, "3-delta-Ct-data-frame.csv"))
  return(dat)
  
}
