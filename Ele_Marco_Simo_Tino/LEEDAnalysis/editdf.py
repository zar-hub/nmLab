import pickle
import numpy as np 
from pprint import pprint

fname = 'LEED_2025_04_23_008'
with open(fname + '.pkl', 'rb') as f:
	settings, original_fits, corrected_fits = pickle.load(f)

print('Loaded File : ', fname )
print('settings : ')
print(settings)
print('%s original_fits len is %s' % (fname, len(original_fits)))
print('%s corrected_fits len is %s' % (fname, len(corrected_fits)))

pprint(corrected_fits[3]['name'])
corrected_fits[3]['name'] = 'LEED_2025_04_23_008_ir0-1_3'
pprint(corrected_fits[3]['name'])

pprint(corrected_fits[4]['name'])
corrected_fits[4]['name'] = 'LEED_2025_04_23_008_ir1-1_4'
pprint(corrected_fits[4]['name'])

pprint(corrected_fits[5]['name'])
corrected_fits[5]['name'] = 'LEED_2025_04_23_008_ir01_5'
pprint(corrected_fits[5]['name'])


# with open(fname + '.pkl', 'wb') as f:
# 	pickle.dump((settings, original_fits, corrected_fits), f)