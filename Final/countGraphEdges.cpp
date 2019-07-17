#include <mex.h>
#include <matrix.h>
#include <cmath>
#include <algorithm>

/**
 * [P, x] = countGraphEdges(y);
 */

void mexFunction(int nlhs, mxArray *plhs[], 
                 int nrhs, const mxArray *prhs[]) {

  // input: y (array of floats)
  float* y = (float*) mxGetPr(prhs[0]);
  size_t ln = mxGetNumberOfElements(prhs[0]);

  plhs[0] = mxCreateDoubleMatrix(1, ln, mxREAL);
  double* P = (double*) mxGetPr(plhs[0]);

  for (size_t am1 = 0; am1 < ln; ++am1) {
    float ya = y[am1];
    for (size_t bm1 = am1 + 2; bm1 < ln; ++bm1) {
      float yb = y[bm1];
      float bma = (float)(bm1) - (float)(am1);
      float coeff = (ya - yb) / bma;
      double fl = 1;
      size_t cm1 = am1 + 1;
      while (cm1 <= bm1 - 1 && fl) {
        float bmc = (float)(bm1) - (float)(cm1);
        if (y[cm1] >= yb + coeff * bmc) {
            fl = 0;
        }
        cm1++;
      }
      //add one to the graph edges of length b-a
      P[bm1-am1-1] += fl;
    }
  }

  // choose an interval in P with no zeros
  auto it = std::find(&P[1], &P[ln], 0.0);
  size_t x = std::distance(&P[0], it) + 1;

  // output: [P, x]
  plhs[1] = mxCreateDoubleScalar((double) x);
}
