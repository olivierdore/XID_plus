//Full Bayesian inference fit  XID
data {
  int<lower=0> nsrc;//number of sources
  //----PSW----
  int<lower=0> npix_psw;//number of pixels
  int<lower=0> nnz_psw; //number of non neg entries in A
  vector[npix_psw] db_psw;//flattened map
  vector[npix_psw] sigma_psw;//flattened uncertianty map (assuming no covariance between pixels)
  real bkg_prior_psw;//prior estimate of background
  real bkg_prior_sig_psw;//sigma of prior estimate of background
  vector[nnz_psw] Val_psw;//non neg values in image matrix
  int Row_psw[nnz_psw];//Rows of non neg valies in image matrix
  int Col_psw[nnz_psw];//Cols of non neg values in image matrix
  vector[nsrc] f_low_lim_psw;//upper limit of flux (in log10)
  vector[nsrc] f_up_lim_psw;//upper limit of flux (in log10)
  //----PMW----
  int<lower=0> npix_pmw;//number of pixels
  int<lower=0> nnz_pmw; //number of non neg entries in A
  vector[npix_pmw] db_pmw;//flattened map
  vector[npix_pmw] sigma_pmw;//flattened uncertianty map (assuming no covariance between pixels)
  real bkg_prior_pmw;//prior estimate of background
  real bkg_prior_sig_pmw;//sigma of prior estimate of background
  vector[nnz_pmw] Val_pmw;//non neg values in image matrix
  int Row_pmw[nnz_pmw];//Rows of non neg valies in image matrix
  int Col_pmw[nnz_pmw];//Cols of non neg values in image matrix
  vector[nsrc] f_low_lim_pmw;//upper limit of flux (in log10)
  vector[nsrc] f_up_lim_pmw;//upper limit of flux (in log10)
  //----PLW----
  int<lower=0> npix_plw;//number of pixels
  int<lower=0> nnz_plw; //number of non neg entries in A
  vector[npix_plw] db_plw;//flattened map
  vector[npix_plw] sigma_plw;//flattened uncertianty map (assuming no covariance between pixels)
  real bkg_prior_plw;//prior estimate of background
  real bkg_prior_sig_plw;//sigma of prior estimate of background
  vector[nnz_plw] Val_plw;//non neg values in image matrix
  int Row_plw[nnz_plw];//Rows of non neg valies in image matrix
  int Col_plw[nnz_plw];//Cols of non neg values in image matrix
  vector[nsrc] f_low_lim_plw;//upper limit of flux (in log10)
  vector[nsrc] f_up_lim_plw;//upper limit of flux (in log10)
  //---colour---
  vector[nsrc] z_mean;// mean for redshift prior
  vector[nsrc] z_sig;//std_dev for redshift prior
  int<lower=0> ncol;//number of points for kcorr prior curves
  vector<lower=0>[ncol] z_kcorr;//redshift for kcorr curve prior
  vector<lower=0.0>[ncol] col_pmw_psw_pred;//prior colour
  vector<lower=0.0>[ncol] col_plw_psw_pred;//prior colour
  vector<lower=0.0>[ncol] col_plw_pmw_pred;//prior colour
  real<lower=0.1> eta_sq;// how much function is allowed to vary from mean      
  real<lower=1> inv_rho_sq;// correlation length
  real<lower=0.1,upper=1> sigma_sq;// noise i.e. how much variance in SED??

}
//transformed data {
//  cholesky_factor_cov[npix_psw] L;

//   for (i in 1:npix_psw) {
//     for (j in 1:npix_psw) {
//       L[i,j]<-0.0;
//     }
//   }
//   for (i in 1:nnz_sig_conf_psw_tot) {
//     L[Row_sig_conf_psw[i],Col_sig_conf_psw[i]]<- Val_sig_conf_psw[i];
//   }


// }

transformed data {
  vector[nsrc+ncol] mu;
  real<lower=0> rho_sq;
  rho_sq <- inv(inv_rho_sq);
  mu <- rep_vector(1, nsrc+ncol);                        # mean function
}

parameters {
  vector<lower=0.0,upper=1.0>[nsrc] src_f_psw;//source vector
  real bkg_psw;//background
  vector<lower=0.0,upper=1.0>[nsrc] src_f_pmw;//source vector
  real bkg_pmw;//background
  vector<lower=0.0,upper=1.0>[nsrc] src_f_plw;//source vector
  real bkg_plw;//background
  real<lower=0.0,upper=8> sigma_conf_psw;
  real<lower=0.0,upper=8> sigma_conf_pmw;
  real<lower=0.0,upper=8> sigma_conf_plw;
  vector<lower=0.0,upper=7>[nsrc] z;

}

model {
  vector[npix_psw] db_hat_psw;//model of map
  vector[npix_pmw] db_hat_pmw;//model of map
  vector[npix_plw] db_hat_plw;//model of map


  vector[npix_psw] sigma_tot_psw;
  vector[npix_pmw] sigma_tot_pmw;
  vector[npix_plw] sigma_tot_plw;

  vector[nsrc] f_vec_psw;//vector of source fluxes
  vector[nsrc] f_vec_pmw;//vector of source fluxes
  vector[nsrc] f_vec_plw;//vector of source fluxes
  vector[nsrc+ncol] col_pmw_psw;
  vector[nsrc+ncol] col_plw_pmw;
  vector[nsrc+ncol] col_plw_psw;
  vector[nsrc+ncol] z_all;

  matrix[nsrc+ncol,nsrc+ncol] Sigma;
  matrix[nsrc+ncol,nsrc+ncol] L;

  //prior on redshift
  z~normal(z_mean,z_sig);

  // Transform to normal space. As I am sampling variable then transforming I don't need a Jacobian adjustment
  for (n in 1:nsrc) {
    f_vec_psw[n] <- f_low_lim_psw[n]+(f_up_lim_psw[n]-f_low_lim_psw[n])*src_f_psw[n];
    f_vec_pmw[n] <- f_low_lim_pmw[n]+(f_up_lim_pmw[n]-f_low_lim_pmw[n])*src_f_pmw[n];
    f_vec_plw[n] <- f_low_lim_plw[n]+(f_up_lim_plw[n]-f_low_lim_plw[n])*src_f_plw[n];
    col_pmw_psw[n] <- f_vec_pmw[n]/f_vec_psw[n];
    col_plw_psw[n] <- f_vec_plw[n]/f_vec_psw[n];
    col_plw_pmw[n] <- f_vec_plw[n]/f_vec_pmw[n];
    z_all[n] <- z[n];
  }
  for (n in 1:ncol) {
    col_pmw_psw[n+nsrc] <- col_pmw_psw_pred[n];
    col_plw_psw[n+nsrc] <- col_plw_psw_pred[n];
    col_plw_pmw[n+nsrc] <- col_plw_pmw_pred[n];
    z_all[n+nsrc] <- z_kcorr[n];
  }
  //Prior on background 
  bkg_psw ~normal(bkg_prior_psw,bkg_prior_sig_psw);
  bkg_pmw ~normal(bkg_prior_pmw,bkg_prior_sig_pmw);
  bkg_plw ~normal(bkg_prior_plw,bkg_prior_sig_plw);

 
   
  // Create model maps (i.e. db_hat = A*f) using sparse multiplication
  for (k in 1:npix_psw) {
    db_hat_psw[k] <- bkg_psw;
    sigma_tot_psw[k]<-sqrt(square(sigma_psw[k])+square(sigma_conf_psw));
  }
  for (k in 1:nnz_psw) {
    db_hat_psw[Row_psw[k]+1] <- db_hat_psw[Row_psw[k]+1] + Val_psw[k]*f_vec_psw[Col_psw[k]+1];
      }

  for (k in 1:npix_pmw) {
    db_hat_pmw[k] <- bkg_pmw;
    sigma_tot_pmw[k]<-sqrt(square(sigma_pmw[k])+square(sigma_conf_pmw));
  }
  for (k in 1:nnz_pmw) {
    db_hat_pmw[Row_pmw[k]+1] <- db_hat_pmw[Row_pmw[k]+1] + Val_pmw[k]*f_vec_pmw[Col_pmw[k]+1];
      }

  for (k in 1:npix_plw) {
    db_hat_plw[k] <- bkg_plw;
    sigma_tot_plw[k]<-sqrt(square(sigma_plw[k])+square(sigma_conf_plw));
  }
  for (k in 1:nnz_plw) {
    db_hat_plw[Row_plw[k]+1] <- db_hat_plw[Row_plw[k]+1] + Val_plw[k]*f_vec_plw[Col_plw[k]+1];
      }



# off-diagonal elements for covariance matrix
  for (i in 1:(nsrc+ncol-1)) {
    for (j in (i+1):nsrc+ncol) {
      Sigma[i,j] <- eta_sq * exp(-rho_sq * pow(z_all[i] - z_all[j],2));
      Sigma[j,i] <- Sigma[i,j];
    }
  }

  # diagonal elements
  for (k in 1:nsrc+ncol)
    Sigma[k,k] <- eta_sq + sigma_sq;             # + jitter for pos def

  L <- cholesky_decompose(Sigma);

  # sampling distribution
  col_pmw_psw  ~ multi_normal_cholesky(mu,L);
  col_plw_psw  ~ multi_normal_cholesky(mu,L);
  col_plw_pmw  ~ multi_normal_cholesky(mu,L);
  
  // likelihood of observed map|model map
  db_psw ~ normal(db_hat_psw,sigma_tot_psw);
  db_pmw ~ normal(db_hat_pmw,sigma_tot_pmw);
  db_plw ~ normal(db_hat_plw,sigma_tot_plw);


    }