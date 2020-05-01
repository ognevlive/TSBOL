rm math/*.sage.py
sage --preparse math/tc.sage
sage --preparse math/dc.sage
sage --preparse math/auxmath.sage
sage --preparse math/shamir.sage
mv -f math/tc.sage.py math/tc.py
mv -f math/dc.sage.py math/dc.py
mv -f math/auxmath.sage.py math/auxmath.py
mv -f math/shamir.sage.py math/shamir.py
rm math/*.sage.py
