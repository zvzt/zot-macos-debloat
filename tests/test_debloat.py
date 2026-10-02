import importlib.machinery
import importlib.util
import json
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest import mock

ROOT=Path(__file__).resolve().parents[1]
LOADER=importlib.machinery.SourceFileLoader("debloat_module",str(ROOT/"debloat"))
SPEC=importlib.util.spec_from_loader(LOADER.name,LOADER)
debloat=importlib.util.module_from_spec(SPEC)
LOADER.exec_module(debloat)

class DebloatTests(unittest.TestCase):
    def test_actual_disabled_parses_true_and_false(self):
        with mock.patch.object(
            debloat,
            "capture",
            return_value=subprocess.CompletedProcess([],0,'disabled services = {\n    "com.test" => true\n}\n',""),
        ):
            self.assertTrue(debloat.actual_disabled("system","com.test"))
        with mock.patch.object(
            debloat,
            "capture",
            return_value=subprocess.CompletedProcess([],0,'disabled services = {\n    "com.test" => false\n}\n',""),
        ):
            self.assertFalse(debloat.actual_disabled("system","com.test"))

    def test_actual_disabled_handles_legacy_wording(self):
        with mock.patch.object(
            debloat,
            "capture",
            return_value=subprocess.CompletedProcess([],0,'"com.test" => disabled\n',""),
        ):
            self.assertTrue(debloat.actual_disabled("gui/501","com.test"))

    def test_state_round_trip(self):
        entry=debloat.encode_state("system","com.example.service")
        self.assertEqual(entry,"system|com.example.service")
        self.assertEqual(debloat.decode_state(entry),("system","com.example.service"))
        self.assertEqual(debloat.decode_state("legacy.label"),(None,"legacy.label"))

    def test_invalid_config_falls_back_to_safe_defaults(self):
        with tempfile.TemporaryDirectory() as temp:
            config_path=Path(temp)/"config.json"
            config_path.write_text(json.dumps({
                "profile":"broken",
                "siri":"broken",
                "intelligence":"broken",
                "spotlight":"broken",
            }))
            with mock.patch.object(debloat,"CONFIG_FILE",config_path):
                config=debloat.load_config()
            self.assertEqual(config,debloat.DEFAULT_CONFIG)

    def test_dry_run_does_not_mutate_state(self):
        with mock.patch.object(debloat,"domains_for",return_value={"user"}), \
             mock.patch.object(debloat,"restore_entry") as restore_entry, \
             mock.patch.object(debloat,"save_state") as save_state, \
             mock.patch.object(debloat,"apply_spotlight") as apply_spotlight:
            debloat.apply(dry_run=True)
        restore_entry.assert_not_called()
        save_state.assert_not_called()
        apply_spotlight.assert_not_called()

    def test_installer_never_creates_root_daemon(self):
        text=(ROOT/"install.sh").read_text()
        self.assertNotIn('sudo tee "$SYSTEM_DAEMON"',text)
        self.assertNotIn('bootstrap system "$SYSTEM_DAEMON"',text)
        self.assertIn("launchctl disable overrides",text)


    def test_human_bytes(self):
        self.assertEqual(debloat.human_bytes(0),"0 B")
        self.assertEqual(debloat.human_bytes(1024),"1.0 KB")
        self.assertEqual(debloat.human_bytes(1024*1024),"1.0 MB")

    def test_clean_dry_run_keeps_files(self):
        with tempfile.TemporaryDirectory() as temp:
            home=Path(temp)
            target=home/"Library"/"Caches"
            target.mkdir(parents=True)
            sample=target/"sample.cache"
            sample.write_text("data")
            targets={"caches":("User app caches",target,"test")}
            with mock.patch.object(debloat,"HOME",home), \
                 mock.patch.object(debloat,"CLEAN_PATH_TARGETS",targets), \
                 mock.patch.object(debloat,"CLEAN_COMMAND_DESCRIPTIONS",{}), \
                 mock.patch.object(debloat,"clean_command",return_value=None):
                debloat.clean(["--caches","--dry-run"])
            self.assertTrue(sample.exists())

    def test_clean_directory_only_clears_allowed_target(self):
        with tempfile.TemporaryDirectory() as temp:
            home=Path(temp)
            target=home/"Library"/"Caches"
            target.mkdir(parents=True)
            (target/"one").write_text("x")
            nested=target/"nested"
            nested.mkdir()
            (nested/"two").write_text("y")
            targets={"caches":("User app caches",target,"test")}
            with mock.patch.object(debloat,"HOME",home), \
                 mock.patch.object(debloat,"CLEAN_PATH_TARGETS",targets):
                _,failures=debloat.clear_directory_contents(target)
            self.assertEqual(failures,0)
            self.assertEqual(list(target.iterdir()),[])

if __name__=="__main__":
    unittest.main()
