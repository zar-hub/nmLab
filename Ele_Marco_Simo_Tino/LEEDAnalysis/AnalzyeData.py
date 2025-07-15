import pickle
import numpy as np 
import pandas as pd
import pprint

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

		# Append Result
		res = make_stats(df)
		results.append(res)

print('\n === RESULTS ===\n')
for i in range(len(results)):
	with pd.option_context('display.max_rows', None, 'display.max_columns', None):
		print('\n\nFILENAME : ', fnames[i])	
		print(results[i])