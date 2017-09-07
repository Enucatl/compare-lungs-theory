import numpy as np
import click
import csv

from nist_lookup import xraydb_plugin as xdb


@click.command()
@click.argument("spectrum_file", type=click.Path(exists=True))
@click.option("--design_energy", type=int, default=45,
              help="design energy (keV)")
@click.option("--talbot_order", type=int, default=1,
              help="talbot order")
@click.option("--output", "-o", type=click.File("w"),
              help="output csv file name")
def calculate_spectrum(
        spectrum_file,
        design_energy,
        talbot_order,
        output):
    spectrum = np.loadtxt(spectrum_file, delimiter=",", skiprows=1)
    output_csv = csv.writer(output)
    output_csv.writerow(
        ["energy", "photons", "n_squared", "beta", "visibility",
            "detector_efficiency", "total_weight",
            "total_weight_no_vis"])
    for energy, photons in spectrum:
        visibility = 2 / np.pi * np.fabs(
            np.sin(np.pi / 2 * design_energy / energy)**2 *
            np.sin(talbot_order * np.pi / 2 * design_energy / energy))
        delta, beta, sample_atlen = xdb.xray_delta_beta(
            'CH12', 1.05, energy * 1e3)
        delta_air, beta_air, _ = xdb.xray_delta_beta(
            'N2', 1.27e-3, energy * 1e3)
        _, _, plastic_atlen = xdb.xray_delta_beta(
            'C2H4', 1.1, energy * 1e3)
        _, _, al_atlen = xdb.xray_delta_beta(
            'Al', 2.7, energy * 1e3)
        _, _, si_atlen = xdb.xray_delta_beta('Si', 2.33, energy * 1e3)
        _, _, au_atlen = xdb.xray_delta_beta('Au', 11.34, energy * 1e3)
        detector_thickness = 0.0450
        detector_thickness = 2
        detector_efficiency = 1 - np.exp(-detector_thickness / si_atlen)
        other_absorption = (
            np.exp(-0.2 / plastic_atlen) *
            np.exp(-0.0016 / al_atlen) *
            np.exp(-0.00194 / au_atlen)
        )  # detector window, holders...
        total_weight_no_vis = (
            photons *
            other_absorption *
            detector_efficiency
        )
        total_weight = total_weight_no_vis * visibility
        n_squared = (delta - delta_air) ** 2 + (beta - beta_air) ** 2
        output_csv.writerow(
            [energy, photons, n_squared, beta, visibility,
                detector_efficiency, 
                total_weight, total_weight_no_vis]
        )


if __name__ == '__main__': calculate_spectrum()
