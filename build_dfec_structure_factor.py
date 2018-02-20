import click
import csv
import numpy as np
from scipy import constants
import dask
import dask.multiprocessing

import logging
import logging.config
from structure_factors.logger_config import config_dictionary

import structure_factors.saxs as saxs
from nist_lookup import xraydb_plugin as xdb

log = logging.getLogger()


def process(energy,
            diameters,
            grating_pitch,
            intergrating_distance,
            volume_fraction,
            sphere_material,
            sphere_density,
            sampling,
           ):
    delta_sphere, beta_sphere, _ = xdb.xray_delta_beta(
        sphere_material,
        sphere_density,
        energy * 1e3)
    delta_chi_squared = delta_sphere ** 2 + beta_sphere ** 2
    wavelength = (
        constants.physical_constants["Planck constant in eV s"][0] *
        constants.c / (energy * 1e3)
    )
    autocorrelation_length = (
        wavelength * intergrating_distance / grating_pitch
    )
    real_space_sampling = np.linspace(
        -4 * autocorrelation_length,
        4 * autocorrelation_length,
        sampling,
        endpoint=False,
    )
    result = []
    for diameter in diameters:
        dfec_lynch = saxs.dark_field_extinction_coefficient(
            wavelength,
            grating_pitch,
            intergrating_distance,
            diameter * 1e-6,
            volume_fraction,
            delta_chi_squared,
            real_space_sampling
        )
        result.append((energy, diameter, dfec_lynch))
    return result


@click.command()
@click.option("--grating_pitch", type=float, default=5.4e-6,
              help="pitch of G2 [m]")
@click.option("--intergrating_distance", type=float, default=26.4e-2,
              help="pitch of G2 [m]")
@click.option("--sphere_material", default="CH12",
              help="chemical composition of the spheres")
@click.option("--sphere_density", type=float, default=1.6,
              help="density of the material of the spheres [g/cm³]")
@click.option("--volume_fraction", type=float, default=0.5,
              help="fraction of the total volume occupied by the spheres")
@click.option("--output", type=click.File("w"), default="-",
              help="output file for the csv data")
@click.option("--sampling", type=int, default=512,
              help="""
              number of cells for the sampling of real and fourier space""")
@click.option("--verbose", is_flag=True, default=False)
def main(
        grating_pitch,
        intergrating_distance,
        volume_fraction,
        sphere_material,
        sphere_density,
        output,
        sampling,
        verbose
        ):
    if verbose:
        config_dictionary['handlers']['default']['level'] = 'DEBUG'
        config_dictionary['loggers']['']['level'] = 'DEBUG'
    logging.config.dictConfig(config_dictionary)
    diameters = np.arange(0.25, 96, 0.25)
    energies = np.arange(20, 101)
    values = [dask.delayed(process)(energy, diameters, grating_pitch,
                                    intergrating_distance, volume_fraction,
                                   sphere_material, sphere_density, sampling)
              for energy in energies]
    results = dask.compute(*values, get=dask.multiprocessing.get)
    output_csv = csv.writer(output)
    output_csv.writerow(
        ["energy", "diameter", "dfec_lynch"]
    )
    for result in results:
        for energy, diameter, dfec_lynch in result:
            output_csv.writerow(
                [energy, diameter, dfec_lynch]
            )

if __name__ == "__main__":
    main()
