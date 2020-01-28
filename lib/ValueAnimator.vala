using GLib;

namespace ValueAnimation {
    public class ValueAnimator : Object {

        public delegate double SpeedFunc (int input);

        public double begining {get; construct;}
        public double end {get; construct;}
        public double current_value {get; private set;}
        public SpeedFunc speed_descriptor;

        private bool stop_signal = false;
        private bool running = true;
        private uint i = 0;

        public signal bool value_changed (double @value);
        public virtual signal void stop () {
            running = false;
            value_changed (end);
            reset ();
        }

        public ValueAnimator (double begining, double end) {
            Object (
                begining: begining,
                end: end
            );
            var end_percent = end/100;
            this.speed_descriptor = (x) => end_percent * ValueAnimatorCurves.smooth ((uint8) x);
        }

        public ValueAnimator.from_function (double begining, double end, SpeedFunc speed_descriptor) {
            this (begining, end);
            var end_percent = end/100;
            this.speed_descriptor = (x) => end_percent * speed_descriptor (x);
        }

        public void start () {
            reset ();
            if (running) stop ();
            running = true;
            Timeout.add (5, () => {
                if (stop_signal || current_value >= end) {
                    stop ();
                    return false;
                }

                stop_signal = ! value_changed (current_value);
                current_value = speed_descriptor ((uint8) (++i)) + begining;
                return true;
            });
        }

        private void reset () {
            current_value = speed_descriptor ((uint8) (i=0)) + begining;
            running = false;
        }
    }

    namespace ValueAnimatorCurves {

        public double bounce (int16 x)
            requires (x <= 100)
            requires (x >= 0)
        {
            if (x <= 40)
                return (x * x)/16.0;
            else if (x <= 70) {
                x -= 55;
                return (x * x)/16.0 + 85.9375;
            } else if (x <= 90) {
                x -= 80;
                return (x * x)/16.0 + 93.75;
            } else if (x < 100) {
                x -= 95;
                return (x * x)/16.0 + 98.4575;
            } else {
                return 101.0;
            }
        }

        public double smooth (uint8 x) 
            requires (x <= 100)
        {
            if (x <= 20)
                return 0.05 * x * x;
            else if (x < 100) {
                var x_over_100 = x/200.0;
                return -500 * x_over_100 * (x_over_100 - 1) - 25;
            } else {
                return 101.0;
            }
        }

        public double linear (int input, double interval) {
            return (double) interval * input;
        }

    }
}