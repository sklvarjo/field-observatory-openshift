#TAKEN FROM PECAN UTILS SO WE WOULD NOT NEED TO INSTALL WHOLE PEcAn FOR THIS

#' Convert units
#'
#' Unit conversion to replace the now-unmaintained `udunits2::ud.convert`
#' @author Chris Black
#'
#' @param x vector of class "numeric" or "difftime"
#' @param u1 string parseable as the units in which `x` is provided.  If `x` is
#'   class "difftime", then `u1` is not actually used.  However, it still needs
#'   to be supplied and needs to be convertible to `u2` for consistency.
#' @param u2 string parseable as the units to convert to
#'
#' @return numeric vector with values converted to units in `u2`
#' @export
ud_convert <- function(x, u1, u2) {
  stopifnot(units::ud_are_convertible(u1, u2))
  if(inherits(x, "difftime")) {
    x1 <- units::as_units(x)
    if(units(x1) != units(units::as_units(u1))) {
      warning("Units of `x` don't match `u1`, using '", units::deparse_unit(x1), "' instead")
    }
  } else {
    x1 <- units::set_units(x, value = u1, mode = "standard")
  }
  x2 <- units::set_units(x1, value = u2, mode = "standard")
  
  units::drop_units(x2)
} # ud_convert

#--------------------------------------------------------------------------------------------------#
#' conversion function for the unit conversions that udunits cannot handle but often needed in PEcAn calculations
#'
#' @export
#' @param x convertible values
#' @param u1 unit to be converted from, character
#' @param u2 unit to be converted to, character
#' @return val converted values
#' @author Istem Fer, Shawn Serbin
local.convert <- function(x, u1, u2) {
  
  amC   <- 12.0107  # atomic mass of carbon
  mmH2O <- 18.01528 # molar mass of H2O, g/mol
  
  if (u1 == "umol C m-2 s-1" & u2 == "kg C m-2 s-1") {
    val <- ud_convert(x, "ug", "kg") * amC
  } else if (u1 == "kg C m-2 s-1" & u2 == "umol C m-2 s-1") {
    val <- ud_convert(x, "kg", "ug") / amC
  } else if (u1 == "mol H2O m-2 s-1" & u2 == "kg H2O m-2 s-1") {
    val <- ud_convert(x, "g", "kg") * mmH2O
  } else if (u1 == "kg H2O m-2 s-1" & u2 == "mol H2O m-2 s-1") {
    val <- ud_convert(x, "kg", "g") / mmH2O
  } else if (u1 == "Mg ha-1" & u2 == "kg C m-2") {
    val <- x * ud_convert(1, "Mg", "kg") * ud_convert(1, "ha-1", "m-2")
  } else if (u1 == "kg C m-2" & u2 == "Mg ha-1") {
    val <- x * ud_convert(1, "kg", "Mg") * ud_convert(1, "m-2", "ha-1")
  } else {
    u1 <- gsub("gC","g*12",u1)
    u2 <- gsub("gC","g*12",u2)
    val <- ud_convert(x,u1,u2)        
    #    PEcAn.logger::logger.severe(paste("Unknown units", u1, u2))
  }
  return(val)
} # local.convert

