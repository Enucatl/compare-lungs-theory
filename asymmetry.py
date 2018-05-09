import click
import numpy as np
import matplotlib.pyplot as plt
import scipy.io


@click.command()
@click.argument("input_file", type=click.Path(exists=True))
@click.argument("output_file", type=click.Path())
def main(input_file, output_file):
    a = scipy.io.loadmat(input_file)["Bf"][:127, 40:140, :]
    transformed = np.fft.fft(a)
    visibility = 2 * np.abs(transformed[1]) / transformed[0]
    print(a.shape)
    median = np.median(a, axis=-1)
    maximum = np.max(a, axis=-1)
    minimum = np.min(a, axis=-1)
    asymmetry = (maximum - minimum) / (maximum + minimum)
    print(asymmetry)
    asymmetry[median > 0.8] = 0
    plt.imshow(asymmetry)
    plt.colorbar()
    print(np.median(asymmetry[asymmetry > 0]))
    print(np.mean(asymmetry[asymmetry > 0]), np.std(asymmetry[asymmetry > 0]))
    plt.clim(0, 1)
    plt.ion()
    plt.show()

    input()


if __name__ == "__main__":
    main()
