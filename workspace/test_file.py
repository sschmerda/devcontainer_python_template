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
# # Test

# %% [markdown]
# ## Import packages

# %% editable=true slideshow={"slide_type": "slide"}
import numpy as np
import pandas as pd
import statsmodels as sm
import matplotlib.pyplot as plt
import seaborn as sns

# %%
from IPython.display import HTML
HTML("""
<style>
.output pre {
    white-space: pre-wrap;
    word-wrap: break-word;
}
</style>
""")


# %% [markdown]
# ## Generate Data

# %%
x = np.random.randint(0, 100, 1000)
y = np.random.normal(50, 5, 1000)
df = pd.DataFrame({"x": x, "y": y})

# %%
df.info()

# %%
df.describe()

# %% [markdown]
# ## Plot

# %%
g = sns.scatterplot(df, x="x", y="y")

# %%
g = sns.kdeplot(df, x="y")

# %% [markdown]
# ## Formula

# %% [markdown]
# $$ F = G \frac{m_1 m_2}{r^2} $$

# %%

# %%
