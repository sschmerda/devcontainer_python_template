# ---
# jupyter:
#   jupytext:
#     formats: ipynb,py:percent
#     text_representation:
#       extension: .py
#       format_name: percent
#       format_version: '1.3'
#       jupytext_version: 1.19.1
#   kernelspec:
#     display_name: Python 3 (ipykernel)
#     language: python
#     name: python3
# ---

# %% [markdown]
# # Heading 1

# %%
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# %%
y = np.random.randint(0, 100, 100)
x = np.random.normal(50, 5, 100)

# %%
data = pd.DataFrame({"x": x, "y": y})
data

# %%
g = sns.scatterplot(data, x=x, y=y)

# %%

# %% [markdown]
# # 
