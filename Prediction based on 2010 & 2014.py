#!/usr/bin/env python
# coding: utf-8

# In[1]:


import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
from sklearn.linear_model import LinearRegression
from sklearn.metrics import r2_score
from sklearn.model_selection import train_test_split
from osgeo import gdal_array
from osgeo import gdal
from sklearn.ensemble import RandomForestClassifier
from sklearn.ensemble import RandomForestRegressor


# In[135]:


output2010 = pd.read_csv(r'C:\ITC\ABM\CASE STUDY_\TRY\tick_2010_new.csv', header=None) # Read the file
output2014 = pd.read_csv(r'C:\ITC\ABM\CASE STUDY_\TRY\tick2014_new.csv', header=None)
array2010 = output2010.to_numpy() # Dataframe to numpy_array
array2014 = output2014.to_numpy()
array2010[np.isnan(array2010)] = 0 #There is some null value, it is replaced to 0.
array2014[np.isnan(array2014)] = 0


# In[136]:


Xtrain = array2010[:,1:] # The output from ABM of 2010 is used as train model. 
Xtest = array2014[:,1:]
ytrain = array2010[:,0] # The output from ABM of 2014 is used as test model.
ytest = array2014[:,0]


# In[137]:


# Use linear regression to investigate the importance of the given parameters
lm = LinearRegression( fit_intercept=True, normalize=False, copy_X=True, n_jobs=1 )
lm.fit(Xtrain, ytrain)
ypred = lm.predict(Xtest)
print("LM: ", r2_score(ytest, ypred))


# In[138]:


from sklearn.ensemble import RandomForestRegressor
from sklearn.datasets import make_regression


# In[146]:


regr = RandomForestRegressor(
  n_estimators = 100, #n_estimators : integer, optional (default=10) The number of trees in the forest.
  criterion = 'mse', #criterion : string, optional (default=”mse”)
#The function to measure the quality of a split.“mse” mean squared error, which is equal to variance reduction as feature selection criterion, and “mae” mean absolute error.
  max_depth = None, #The maximum depth of the tree. 
    #If None, then nodes are expanded until all leaves are pure or until all leaves contain less than min_samples_split samples.
  max_features = 'auto', #If “auto”, then max_features=n_features
  bootstrap = True,#Whether bootstrap samples are used when building trees. 
    #If False, the whole datset is used to build each tree.
  min_samples_split = 40, #(default=2)
  n_jobs = 1 #The number of jobs to run in parallel for both fit and predict.
)


# In[147]:


regr.fit(Xtrain,ytrain)
ypred2 = regr.predict(Xtest)
print("RF: ", r2_score(ytest,ypred2))


# In[118]:


np.savetxt('C:/ITC/ABM/CASE STUDY_/TRY/new.csv', ypred2, delimiter = ',')

