import pickle
import numpy as np 
import pandas as pd
import pprint
import matplotlib.pyplot as plt

def pretty(d, indent=0):
   for key, value in d.items():
      print('\t' * indent + str(key))
      if isinstance(value, dict):
         pretty(value, indent+1)
      else:
         print('\t' * (indent+1) + str(value))

def parser(item):
	s = item['name']
	splitted = s.split('_')
	i = splitted[-1]
	typ = splitted[-2][:2]
	ori = splitted[-2][2:]
	fname = '_'.join(splitted[:-2])
	center =  np.array([item['popt'][1][2], item['popt'][2][2]]) 
	ser = pd.Series({
		'id' : i,
		'fname' : fname,
		'type' : typ,
		'orientation' : ori,
		'center' : center
		})
	# print(ser)

	return ser

def length(v):
		return np.sqrt(np.square(v).sum())

def minlength(v, centers):
	l = [length(v - c) for c in centers]
	return np.min(l)

def add_length(batch):
	'''
    batch: pandas DataFrame containing one day's data
    Required columns: 'type', 'orientation', 'center'
    Assumes presence of `minlength` and `length` functions.
    Modifies batch in-place by adding a 'length' column.
    '''
    # Boolean masks
	ir_batch = batch['type'] == 'ir'
	mo_batch = batch['type'] == 'mo'

    # Find the 'zero' point: first 'ir' with orientation == '00'
	zero_row = batch[(ir_batch) & (batch['orientation'] == '00')]
	if zero_row.empty:
		raise ValueError("No 'ir' row with orientation '00' found.")
	zero = zero_row['center'].values[0]

    # Get centers for ir
	centers = batch.loc[ir_batch, 'center'].values

    # Initialize 'length' column if it doesn't exist
	if 'length' not in batch.columns:
		batch['length'] = None

    # Apply minlength to 'mo' rows
	batch.loc[mo_batch, 'length'] = batch.loc[mo_batch, 'center'].apply(
		lambda x: minlength(x, centers=centers)
	)

    # Apply length to 'ir' rows
	batch.loc[ir_batch, 'length'] = batch.loc[ir_batch, 'center'].apply(
		lambda x: length(x - zero)
	)

	return batch

def make_stats(batch):
	batch = add_length(batch)
	batch = batch[batch['orientation'] != '00']
	res = batch.groupby(['orientation', 'type']).agg(
			mean_length=('length', 'mean'),
			std_length=('length', 'std')
		)
	# Fill Nan to 0 
	# If there is only one value assume
	# its correct
	res =res.fillna(0)

	# Pivot so that 'mo' and 'ir' become columns
	pivot = res.unstack('type')
	
    # Compute mean_ratio and error (std error propagation)
	pivot['mean_ratio'] = pivot['mean_length']['mo'] / pivot['mean_length']['ir']
	pivot['std_error'] = pivot['mean_ratio'] * (
		(pivot['std_length']['mo'] / pivot['mean_length']['mo']) ** 2 +
		(pivot['std_length']['ir'] / pivot['mean_length']['ir']) ** 2
	) ** 0.5

	# Flatten columns
	pivot.columns = ['_'.join(col).strip() for col in pivot.columns.values]
	# pivot = pivot.reset_index()

	return pivot

if __name__ == '__main__':

	fnames = ['LEED_2025_04_23_006', 'LEED_2025_04_23_007','LEED_2025_04_23_008', 'LEED_2025_04_23_009']
	data = []
	results = []


	for fname in fnames:
		with open(fname + '.pkl', 'rb') as f:
		    settings, original_fits, corrected_fits = pickle.load(f)

		print('Loaded File : ', fname )
		print('settings : ')
		pprint.pprint(settings)
		print('%s original_fits len is %s' % (fname, len(original_fits)))
		print('%s corrected_fits len is %s' % (fname, len(corrected_fits)))


		df = pd.DataFrame(map(parser, corrected_fits))
		df.set_index('id', inplace=True)
		print('\n=== INPUT DATA ===\n')
		print(df[['type', 'orientation', 'center']])

		# Append Data
		data.append(df)

		# Append Result
		res = make_stats(df)
		results.append(res)

print('\n === RESULTS ===\n')

res_file = open('results.txt', 'w')
for i in range(len(results)):
	
	with pd.option_context('display.max_rows', None, 'display.max_columns', None):
		res_file.write('\n\n\n\nFILENAME : %s\n' % fnames[i])
		res_file.write('__________________________________________________________________\n')
		res_file.write(results[i].to_string())
		s = print('\n\nFILENAME : ', fnames[i])	
		print(results[i])
res_file.close()


oriToTheta = {
	'10' : 0, 
	'01' : np.pi / 3,
	'-11' : np.pi * 2 / 3,
	'-10' : np.pi,
	'0-1' : np.pi * 4 / 3,
	'1-1' : np.pi * 5 / 3,
}

# Now do a cumulative analysis
data = pd.concat(data)

#fig, ax = plt.subplots(subplot_kw={'projection': 'polar'})
# data.apply(lambda x : ax.scatter(oriToTheta[x['orientation']], x['length']), axis = 1)



fig, ax = plt.subplots()
def pf(x, ax):
	print(x['type'], x['orientation'])
	if x['type'] == 'ir':
		ax.scatter(*x['center'], marker = '.', alpha = 0.7, c ='red')
	else:
		ax.scatter(*x['center'], marker = 'x', alpha = 0.3, c ='blue')


data.apply(pf, ax = ax,  axis = 1)
#ax.set_rmax(180)
#ax.set_rticks([10, 20, 150, 160, 170, 180])  # Less radial ticks
#ax.set_rlabel_position(-22.5)  # Move radial labels away from plotted line


ax.set_title("LEED DATA", va='bottom')
plt.show()


data = data[data['orientation'] != '00']
with pd.option_context('display.max_rows', None, 'display.max_columns', None):
	print(data[['fname', 'type', 'orientation', 'length']])
	cum_res = data.groupby(['type', 'orientation']).agg(
		mean_length = ('length', 'mean'),
		std_length = ('length', 'std')
	)
	cum_res = cum_res.unstack('type')

	cum_res['mean_ratio'] = cum_res['mean_length']['mo'] / cum_res['mean_length']['ir']
	cum_res['std_error'] = cum_res['mean_ratio'] * (
		(cum_res['std_length']['mo'] / cum_res['mean_length']['mo']) ** 2 +
		(cum_res['std_length']['ir'] / cum_res['mean_length']['ir']) ** 2
	) ** 0.5

	# Flatten columns
	cum_res.columns = ['_'.join(col).strip() for col in cum_res.columns.values]
	print(cum_res)
