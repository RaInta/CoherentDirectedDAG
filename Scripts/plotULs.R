#!/usr/bin/R

# This is designed to read a search_results.txt file as the result of calling 
# ComputeFstatistic_v2
# This was written in R, and is largely taken from a couple of introductory 
# classes on R.
#
#
# Created: 4 May 2015, Ra Inta
# Modified: 20150504, R.I.

library(XML)
library(scales)
library(ggplot2) 

ul_doc  <- xmlParse("upper_limit_bands.xml" )
ul_data <- xmlToDataFrame(nodes = getNodeSet(ul_doc, "//upper_limit_band/loudest_nonvetoed_template"), stringsAsFactors=FALSE)
ul_data_h0 <- xmlToDataFrame(nodes = getNodeSet(ul_doc, "//upper_limit_band/upper_limit_h0"), stringsAsFactors=FALSE)
names(ul_data_h0)  <- "upper_limit"
ul_data <- cbind(ul_data,ul_data_h0)
names(ul_data)
ul_data <- transform(ul_data, freq=as.numeric(freq), twoF=as.numeric(twoF), twoF_H1=as.numeric(twoF_H1), twoF_L1=as.numeric(twoF_L1), upper_limit=as.numeric(upper_limit))



veto_doc  <- xmlParse("veto_bands.xml")
veto_data <- xmlToDataFrame(nodes = getNodeSet(veto_doc, "//veto_band"), stringsAsFactors=FALSE)
names(veto_data)[3]  <- "fscan_power"
names(veto_data)
veto_data  <- transform(veto_data, band=as.numeric(band), freq=as.numeric(freq), fscan_power=as.numeric(fscan_power))


ul_plot <- ggplot(data=veto_data, aes(x=veto_data$freq, y=1.1*max(ul_data$upper_limit) ) ) + geom_bar(colour="tan", stat="identity", width=veto_data$band, fill="tan") + geom_point(data=ul_data, aes(x = ul_data$freq, y = ul_data$upper_limit, fill="black")) 

# Label axes and legends
ul_plot <- ul_plot + xlab("Frequency (Hz)") + ggtitle("Upper limit plot") + ylab("h0") + theme(axis.text=element_text(size=12), axis.title=element_text(size=14,face="bold")) 
