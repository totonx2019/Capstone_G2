# -*- coding: utf-8 -*-
"""
Spyder Editor

This is a temporary script file.
"""

import investpy
#wd = "D:\\trading\\CAPSTONE\\DATA"
wd = "C:\\MyDisk\\Resilio\\folder2"
import os
#import pandas as pd
os.chdir(wd)
os.getcwd()
#df = investpy.get_stock_recent_data(stock='bbva', country='spain', as_json=False, order='ascending')
#asset = investpy.get_bond_historical_data(bond=assetname, from_date='01/01/2010', to_date='01/01/2020')
#asset = investpy.get_fund_historical_data(fund='bbva plan multiactivo moderado pp',country='spain',from_date='01/01/2010',to_date='01/01/2019')
#asset = investpy.get_etf_historical_data(etf='bbva accion dj eurostoxx 50',country='spain',from_date='01/01/2018',to_date='01/01/2019')
#asset = investpy.get_index_historical_data(index='ibex 35',country='spain',from_date='01/01/2018',to_date='01/01/2019')
#asset = investpy.get_currency_cross_historical_data(currency_cross='EUR/USD',from_date='01/01/2018',to_date='01/01/2019')
#asset = investpy.get_crypto_historical_data(crypto='bitcoin', from_date='01/01/2010', to_date='01/01/2020', as_json=False, order='ascending', interval='Daily')
#asset = investpy.get_commodity_historical_data(commodity='gold', from_date='01/01/2018',to_date='01/01/2019')
#asset = investpy.get_fund_historical_data(fund=assetname,country='spain',from_date='01/01/2010',to_date='01/01/2021')
#asset = investpy.get_etf_historical_data(etf=assetname,country='spain',from_date='01/01/2010',to_date='01/01/2021')
#==============================================================================
def get_Bond(assetname):
    asset = investpy.get_bond_historical_data(bond=assetname, from_date='01/01/2010', to_date='01/01/2021')
    filename = assetname.replace(".", "")
    filename = filename.replace("/", "")
    filename = filename.replace(" ", "")
    asset.to_csv(wd+'\\toto_data\\'+'bond-'+filename+'.csv')

get_Bond('U.S. 30Y')
get_Bond('U.S. 10Y')
get_Bond('U.S. 5Y')
get_Bond('U.S. 2Y')
get_Bond('Canada 10Y')
get_Bond('Brazil 10Y')
get_Bond('Germany 10Y')
get_Bond('France 10Y')
get_Bond('U.K. 10Y')
get_Bond('Spain 10Y')
get_Bond('Italy 10Y')
get_Bond('Japan 10Y')
get_Bond('Australia 10Y')
get_Bond('Hong Kong 10Y')

#==============================================================================
def get_Index(countryname,assetname):
    asset = investpy.get_index_historical_data(index=assetname,country=countryname,from_date='01/01/2010',to_date='01/01/2021')
    filename = assetname.replace(".", "")
    filename = filename.replace("/", "")
    filename = filename.replace(" ", "")
    filename = filename.replace("&", "")
    asset.to_csv(wd+'\\toto_data\\'+'index-'+countryname+'-'+filename+'.csv')

get_Index('Argentina','S&P Merval')
get_Index('Brazil','Brazil 50')
get_Index('Canada','S&P/TSX 60')
get_Index('United States','S&P 500')
get_Index('United States','DJ Composite')
get_Index('United States','Nasdaq 100')
get_Index('Venezuela','Bursatil')
#******************
get_Index('Austria','ATX Prime')
get_Index('Belgium','BEL 20')
get_Index('Denmark','OMXC20')
get_Index('Finland','OMX Helsinki 25')
get_Index('France','CAC 40')
get_Index('Germany','DAX')
get_Index('Greece','FTSE/Athex 20')
get_Index('Hungary','Budapest SE')
get_Index('Ireland','ISEQ Overall')
get_Index('Italy','Italy 40')
get_Index('Netherlands','AEX')
get_Index('Russia','MOEX')
get_Index('Spain','IBEX 35')
get_Index('Sweden','OMXS30')
get_Index('Switzerland','SMI')
get_Index('United Kingdom','FTSE 100')
#******************
get_Index('Australia','S&P/ASX 200')
get_Index('China','Shanghai')
get_Index('China','China A50')
get_Index('Hong Kong','Hang Seng')
get_Index('India','Nifty 50')
get_Index('India','BSE Sensex')
get_Index('Indonesia','IDX Composite')
get_Index('Japan','Nikkei 225')
get_Index('Malaysia','Malaysia Top 100')
get_Index('New Zealand','NZX 50')
get_Index('Philippines','PSEi Composite')
get_Index('Singapore','FTSE Singapore')
get_Index('South Korea','KOSPI 50')
get_Index('Taiwan','TSEC Taiwan 50')
get_Index('Thailand','SET 100')
get_Index('Vietnam','VN100')

#==============================================================================
def get_Currency(assetname):
    asset = investpy.get_currency_cross_historical_data(currency_cross=assetname,from_date='01/01/2010',to_date='01/01/2021')
    filename = assetname.replace(".", "")
    filename = filename.replace("/", "")
    filename = filename.replace(" ", "")
    filename = filename.replace("&", "")
    asset.to_csv(wd+'\\toto_data\\'+'fx-'+filename+'.csv')

get_Currency('EUR/USD')
get_Currency('GBP/USD')
get_Currency('USD/JPY')
get_Currency('USD/CHF')
get_Currency('AUD/USD')
get_Currency('EUR/GBP')
get_Currency('USD/CAD')
get_Currency('NZD/USD')
get_Currency('EUR/JPY')
get_Currency('GBP/JPY')

#==============================================================================
def get_Cryptro(assetname):
    asset = investpy.get_crypto_historical_data(crypto=assetname, from_date='01/01/2010', to_date='01/01/2021')
    filename = assetname.replace(".", "")
    filename = filename.replace("/", "")
    filename = filename.replace(" ", "")
    filename = filename.replace("&", "")
    asset.to_csv(wd+'\\toto_data\\'+'crypto-'+filename+'.csv')

get_Cryptro('Bitcoin')
get_Cryptro('Ethereum')
get_Cryptro('Tether')
get_Cryptro('XRP')
get_Cryptro('EOS')

#==============================================================================
def get_Commodity(assetname):
    asset = investpy.get_commodity_historical_data(commodity=assetname,country='united states', from_date='01/01/2010',to_date='01/01/2021')
    filename = assetname.replace(".", "")
    filename = filename.replace("/", "")
    filename = filename.replace(" ", "")
    filename = filename.replace("&", "")
    asset.to_csv(wd+'\\toto_data\\'+'commo-'+filename+'.csv')

get_Commodity('Aluminum')
get_Commodity('Copper')
get_Commodity('Gold')
get_Commodity('Lead')
get_Commodity('Nickel')
get_Commodity('Palladium')
get_Commodity('Platinum')
get_Commodity('Silver')
get_Commodity('Tin')
get_Commodity('Zinc')
get_Commodity('Brent Oil')
get_Commodity('Carbon Emissions')
get_Commodity('Gasoline RBOB')
get_Commodity('Heating Oil')
get_Commodity('London Gas Oil')
get_Commodity('Natural Gas')
get_Commodity('Crude Oil WTI')
    
#==============================================================================